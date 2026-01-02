import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class OauthboxManagerController extends Controller {
  @tracked providers = [];
  @tracked loading = true;
  @tracked showModal = false;
  @tracked editingProvider = null;
  @tracked saving = false;

  @tracked formData = {
    name: "",
    button_title: "OauthBox登录点",
    client_id: "",
    client_secret: "",
    authorize_url: "",
    token_url: "",
    token_url_method: "POST",
    user_json_url: "",
    user_json_url_method: "GET",
    scope: "",
    authorize_options: "",
    authorize_signup_url: "",
    send_auth_header: true,
    send_auth_body: true,
    email_verified: false,
    overrides_email: false,
    allow_association_change: false,
    callback_user_id_path: "",
    callback_user_info_paths: "id",
    fetch_user_details: true,
    json_user_id_path: "",
    json_username_path: "",
    json_name_path: "",
    json_email_path: "",
    json_email_verified_path: "",
    json_avatar_path: "",
    position: 0,
    enabled: true
  };

  constructor() {
    super(...arguments);
    this.loadProviders();
  }

  get sortedProviders() {
    return this.providers.sort((a, b) => a.position - b.position);
  }

  @action
  async loadProviders() {
    this.loading = true;
    try {
      const result = await ajax("/oauthbox/admin");
      this.providers = result.providers || [];
    } catch (error) {
      console.error("加载提供商列表失败:", error);
      this.providers = [];
      popupAjaxError(error);
    } finally {
      this.loading = false;
    }
  }

  @action
  showAddModal() {
    this.editingProvider = null;
    this.formData = {
      name: "",
      button_title: "OauthBox登录点",
      client_id: "",
      client_secret: "",
      authorize_url: "",
      token_url: "",
      token_url_method: "POST",
      user_json_url: "",
      user_json_url_method: "GET",
      scope: "",
      authorize_options: "",
      authorize_signup_url: "",
      send_auth_header: true,
      send_auth_body: true,
      email_verified: false,
      overrides_email: false,
      allow_association_change: false,
      callback_user_id_path: "",
      callback_user_info_paths: "id",
      fetch_user_details: true,
      json_user_id_path: "",
      json_username_path: "",
      json_name_path: "",
      json_email_path: "",
      json_email_verified_path: "",
      json_avatar_path: "",
      position: this.providers.length + 1,
      enabled: true
    };
    this.showModal = true;
  }

  @action
  showEditModal(provider) {
    this.editingProvider = provider;
    this.formData = {
      name: provider.name || "",
      button_title: provider.button_title || "",
      client_id: provider.client_id || "",
      client_secret: provider.client_secret || "",
      authorize_url: provider.authorize_url || "",
      token_url: provider.token_url || "",
      token_url_method: provider.token_url_method || "POST",
      user_json_url: provider.user_json_url || "",
      user_json_url_method: provider.user_json_url_method || "GET",
      scope: provider.scope || "",
      authorize_options: provider.authorize_options || "",
      authorize_signup_url: provider.authorize_signup_url || "",
      send_auth_header: provider.send_auth_header || false,
      send_auth_body: provider.send_auth_body || false,
      email_verified: provider.email_verified || false,
      overrides_email: provider.overrides_email || false,
      allow_association_change: provider.allow_association_change || false,
      callback_user_id_path: provider.callback_user_id_path || "",
      callback_user_info_paths: provider.callback_user_info_paths || "",
      fetch_user_details: provider.fetch_user_details || false,
      json_user_id_path: provider.json_user_id_path || "",
      json_username_path: provider.json_username_path || "",
      json_name_path: provider.json_name_path || "",
      json_email_path: provider.json_email_path || "",
      json_email_verified_path: provider.json_email_verified_path || "",
      json_avatar_path: provider.json_avatar_path || "",
      position: provider.position || 1,
      enabled: provider.enabled !== undefined ? provider.enabled : true
    };
    this.showModal = true;
  }

  @action
  closeModal() {
    this.showModal = false;
    this.editingProvider = null;
  }

  @action
  updateTokenUrlMethod(event) {
    this.formData.token_url_method = event.target.value;
  }

  @action
  updateUserJsonUrlMethod(event) {
    this.formData.user_json_url_method = event.target.value;
  }

  @action
  async saveProvider() {
    this.saving = true;
    try {
      let response;
      if (this.editingProvider) {
        response = await ajax(`/oauthbox/admin/${this.editingProvider.id}`, {
          type: "PUT",
          data: { provider: this.formData }
        });
      } else {
        response = await ajax("/oauthbox/admin", {
          type: "POST",
          data: { provider: this.formData }
        });
      }
      this.closeModal();
      await this.loadProviders();
    } catch (error) {
      console.error("保存提供商失败:", error);
      // 确保使用popupAjaxError处理错误，它能处理非JSON响应
      popupAjaxError(error);
    } finally {
      this.saving = false;
    }
  }

  @action
  async toggleProvider(provider) {
    try {
      await ajax(`/oauthbox/admin/${provider.id}`, {
        type: "PUT",
        data: { provider: { enabled: !provider.enabled } }
      });
      await this.loadProviders();
    } catch (error) {
      console.error("切换提供商状态失败:", error);
      popupAjaxError(error);
    }
  }

  @action
  async deleteProvider(provider) {
    if (confirm(I18n.t("oauthbox.manager.confirm_delete"))) {
      try {
        await ajax(`/oauthbox/admin/${provider.id}`, {
          type: "DELETE"
        });
        await this.loadProviders();
      } catch (error) {
        console.error("删除提供商失败:", error);
        popupAjaxError(error);
      }
    }
  }
}