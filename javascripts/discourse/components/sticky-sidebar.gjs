import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { modifier } from "ember-modifier";

export default class StickySidebar extends Component {
  @service router;
  @tracked isSticky = false;
  @tracked sidebarHeight = 0;

  setupStickyBehavior = modifier((element) => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          this.isSticky = !entry.isIntersecting;
        });
      },
      {
        threshold: 0,
        rootMargin: "-60px 0px 0px 0px",
      }
    );

    const sentinel = document.createElement("div");
    sentinel.style.height = "1px";
    element.parentNode.insertBefore(sentinel, element);
    observer.observe(sentinel);

    // Calculate sidebar height
    const updateHeight = () => {
      const windowHeight = window.innerHeight;
      const headerHeight = 60;
      this.sidebarHeight = windowHeight - headerHeight;
    };

    updateHeight();
    window.addEventListener("resize", updateHeight);

    return () => {
      observer.disconnect();
      window.removeEventListener("resize", updateHeight);
      if (sentinel.parentNode) {
        sentinel.parentNode.removeChild(sentinel);
      }
    };
  });

  get sidebarStyle() {
    if (this.isSticky) {
      return `position: fixed; top: 60px; height: ${this.sidebarHeight}px; overflow-y: auto; z-index: 100;`;
    }
    return "";
  }

  <template>
    <div
      class="sidebar-wrapper {{if this.isSticky 'is-sticky'}}"
      style={{this.sidebarStyle}}
      {{this.setupStickyBehavior}}
    >
      {{yield}}
    </div>
  </template>
}
