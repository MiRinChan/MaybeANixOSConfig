{pkgs, ...}: {
  programs.mcp = {
    enable = true;
    servers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    skills.nixos = "${pkgs.fetchFromGitHub {
      owner = "marceloeatworld";
      repo = "nixos-ai-skill";
      rev = "922573e59bcd8eef7e9a7a5f9b40a28812d39357";
      sha256 = "125agnm8kmvg3rr3a07lwp9dfdyxki2s2q4rm8y8v2qrc03iimb5";
    }}";

    settings = {
      features.memories = true;
      memories.no_memories_if_mcp_or_web_search = true;
    };
  };
}
