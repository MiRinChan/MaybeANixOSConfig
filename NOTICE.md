# NOTICE.md

给我自己和后续 agent 看的备忘。记录**不在声明式配置里、但必须知道**的虚拟机 + GPU 决策。
其余声明式状态以 `.nix` 文件为准。

> 最后更新:2026-05-29 · 范围:QEMU/KVM + virt-manager + GPU 共享

---

## 1. 已加入声明式配置的部分

QEMU/KVM 用 libvirt 做后端、virt-manager 做前端,和原有的 VirtualBox / Docker 并存。

- [`modules/nixos/ProgramFiles/virtualMachine.nix`](modules/nixos/ProgramFiles/virtualMachine.nix)
  - `virtualisation.libvirtd.enable`,qemu 用 `pkgs.qemu_kvm`,`runAsRoot = true`
  - `swtpm.enable = true`(Windows 11 客户机要的软件 TPM)
  - `ovmf.packages = [pkgs.OVMFFull.fd]`(UEFI 固件 + 客户机 Secure Boot)
  - `programs.virt-manager.enable = true`
  - `virtualisation.spiceUSBRedirection.enable = true`(SPICE 查看器透传 USB)
- [`System32/UsersConf.nix`](System32/UsersConf.nix#L12) — `mirin` 加入 `libvirtd` 组(免 sudo 管理 VM)
- `programs.dconf.enable` 早已在 [`System32/configuration.nix`](System32/configuration.nix#L202) 开启,virt-manager 存设置需要它

应用后**要重新登录或重启**,`libvirtd` 组才对当前会话生效,否则 virt-manager 连不上系统 libvirt socket。
默认 NAT 网络若没起:`sudo virsh net-start default && sudo virsh net-autostart default`(一次性)。

---

## 2. 硬件约束(决定 GPU 方案的关键)

- 无集成显卡。
- GPU:**单张独立 NVIDIA 卡**(见 [`modules/nixos/DRIVER/nvidia.nix`](modules/nixos/DRIVER/nvidia.nix),`open = true`,Turing+)。
- 所以宿主桌面(Plasma)始终占着唯一这块卡,**没有第二个显示输出兜底**。

由此得出的硬结论:

| 方案 | 能否宿主 + VM 同时用 | 说明 |
|------|------|------|
| 完整 PCI 直通 (VFIO) | **否** | 单显卡直通:VM 一开宿主桌面就黑屏,关 VM 才回来 |
| vGPU / SR-IOV | **否** | NVIDIA 消费卡官方不支持;`vgpu_unlock` 仅限老架构、不稳定 |
| virtio-gpu (VirGL / Venus) | **是** ✅ | 半虚拟化,API 转发到宿主 GPU;宿主继续正常用卡 |

**当前选定方向:virtio-gpu,目标是给 Linux 客户机一个加速桌面。**
要在 VM 里全速打 Windows 游戏 / 跑 CUDA,只能上单显卡直通或加第二块亮机卡——届时另行评估。

---

## 3. GPU 加速是**逐虚拟机**配的,不在 nix 里

加速开关在单个 VM 的 libvirt domain XML 里,**不是声明式的**,重建系统不会自动带上。
host 侧软件栈已就绪(下面已核实),无需改 `.nix`。

### host 能力(2026-05-29 实测)

- `pkgs.virglrenderer` = **1.3.0**,mesonFlags 含 **`-Dvenus=true`** → VirGL 和 Venus backend 都现成。
- `pkgs.qemu_kvm` = **10.2.2** → 远超 venus 所需的 8.1+。
- `hardware.graphics.enable = true` 提供宿主 EGL/GL/Vulkan 栈。
- **结论:不需要 override 重编 virglrenderer/qemu。**

### 方式 A —— VirGL(OpenGL,推荐,较稳)

virt-manager 里(灯泡图标 → 硬件详情):

1. Video → Model `Virtio`,勾 **3D acceleration**
2. Display Spice → Listen type `None`,勾 **OpenGL**,Render node 选 N 卡的 `renderD128`
3. 删掉多余的 Display(如 VNC),只留这个 Spice

客户机里验证:`glxinfo | grep -i renderer` 出现 `virgl` 即生效。

### 方式 B —— Venus(Vulkan,进阶,实验性)

GUI 不暴露 venus 属性,需手动加 qemu 参数:

1. virt-manager → Edit → Preferences → 勾 **Enable XML editing**
2. 先按方式 A 设好 Video/Display
3. VM 的 XML 标签页,根节点加 qemu 命名空间并追加:

```xml
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
  ...
  <qemu:commandline>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.video0.blob=true'/>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.video0.venus=true'/>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.video0.hostmem=8G'/>
  </qemu:commandline>
</domain>
```

- venus **必须**配 `blob=true` + `hostmem`(blob 窗口大小)。
- `device.video0` 是 libvirt 分配的显卡别名;**先 `virsh dumpxml <vm> | grep alias` 确认**,不对就改名。
- 客户机用较新 Mesa(自带 venus ICD),验证:`vulkaninfo | grep -iE "deviceName|venus"`。

---

## 4. 坑 / 注意事项

- **SPICE GL(gl=on)只能本地 viewer 看**,渲染在宿主本地完成,不能走网络串流。virt-manager 自带本地查看器没问题。
- **NVIDIA 闭源驱动当宿主 Vulkan 跑 venus 是最少被测的组合**(venus 主要在 radv/anv/turnip 上验证)。不稳就退回 VirGL。
- VirGL/Venus 都是 **API 转发,性能非原生**:桌面合成、轻量 3D、视频解码顺;别拿来在 VM 里认真打游戏。
- 主要面向 **Linux 客户机**;Windows 走 virtio-gpu 3D 加速很差/基本不可用。
- VirtualBox 与 libvirt/KVM 可共存,但**同一台 VM 同一时刻只让一个 hypervisor 跑**。
