import Route from "@ember/routing/route";
import { inject as service } from "@ember/service";

export default class OauthboxManagerRoute extends Route {
  @service router;

  setupController(controller) {
    controller.loadProviders();
  }
}
