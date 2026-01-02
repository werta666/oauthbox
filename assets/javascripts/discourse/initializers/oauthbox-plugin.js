import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "oauthbox-plugin",

  initialize() {
    console.log("🔐 OAuthbox 插件正在初始化...");

    withPluginApi("1.0.0", (api) => {
      console.log("🔐 OAuthbox Plugin API 已成功初始化");
      console.log("🔐 OAuthbox 插件功能就绪。");
      console.log("🔐 OAuthbox 按钮将根据后端配置显示。");

      const siteSettings = api.siteSettings;
      if (siteSettings) {
        console.log("🔐 OAuthbox 全局设置已加载:");
        console.log("  - oauthbox_enabled:", siteSettings.oauthbox_enabled);
        console.log("  - 已就绪，等待后端认证器注册...");
      }
    });
  }
};
