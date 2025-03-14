### Maybe a NixOS config ###
I have to say I take a loooot of config from community.
And I didn't tell anyone I take it and I forget to label 
the code from who.

Sorry.

By the way, you can take it and needn't let me know. 

And I didn't make all into declarative. YOU MAY GET 
DIFFERENT RESULT.

Todo list:
    [x] C 语言环境搭建 注：虚拟机然后 SSH 进去搞的
    [] 学习 C 语言 flag：真的要完成 X_X


Note: 
    用 Bottles 打不开窗口的解决办法（不优雅
        ~/.local/share/flatpak/overrides/

        [Context]
        sockets=x11;

    光标在 GTK Flatpak 里变大变高（在 GTK 4.18 修复 将于 2025 三月发布 https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/7722）
        $ dconf write /org/gnome/desktop/interface/cursor-size 32

    Fullscreen go to black screen. see https://bugs.kde.org/show_bug.cgi?id=427920.
        Close VRR. System Settings -> Display configuration -> Adaptive Sync: Never.

    Wine 里打补丁之类的修改 dll 操作
        一定要在 winecfg 里要求使用 native, builtin

    推流 WebCam
        gphoto2 --stdout --capture-movie |
        ffmpeg -i - -vcodec rawvideo -pix_fmt yuv420p -f v4l2 /dev/video0
