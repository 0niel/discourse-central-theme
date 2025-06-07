import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { htmlSafe } from "@ember/template";
import scroll from "../modifiers/scroll";

function isTopInView(element, yOffset) {
  const rect = element.getBoundingClientRect();
  return rect.top >= yOffset && rect.top <= window.innerHeight;
}

function isBottomInView(element) {
  const rect = element.getBoundingClientRect();
  return rect.bottom >= 0 && rect.bottom <= window.innerHeight;
}

function getYOrigin(el) {
  const rect = el.getBoundingClientRect();
  const scrollTop = window.scrollY || window.pageYOffset;
  return rect.top + scrollTop;
}

export default class StickySidebar extends Component {
  @tracked top = 0;
  @tracked bottom = 0;
  @tracked position = "relative";
  @tracked transition = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)";
  @tracked opacity = 1;
  @tracked transform = "translateY(0)";
  headerHeight = 72;
  offset = 0;
  prevScrollTop = 0;
  yOrigin = 0;
  mode = "top";

  @action
  onScroll() {
    const scrollY = window.scrollY;
    const scrollingUp = scrollY < this.prevScrollTop;
    const scrollingDown = scrollY > this.prevScrollTop;
    const element = this.element;

    const isScrolledToBottom =
      window.innerHeight + scrollY >= document.documentElement.scrollHeight;
    if (!this.yOrigin) {
      // save the initial vertical position
      this.yOrigin = getYOrigin(this.element);
    }

    if (scrollingUp) {
      switch (this.mode) {
        case "between":
          if (isTopInView(element, this.headerHeight)) {
            this.mode = "pinned";
            this.position = "fixed";
            this.top = `${this.headerHeight}px`;
            this.bottom = "unset";
            this.transition = "all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)";
            this.opacity = 1;
            this.transform = "translateY(0) scale(1)";
          }
          break;
        case "pinned":
          if (scrollY < this.yOrigin - this.headerHeight) {
            this.mode = "top";
            this.position = "relative";
            this.top = 0;
            this.bottom = "unset";
            this.transition = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)";
            this.opacity = 1;
            this.transform = "translateY(0) scale(1)";
          }
          break;
        case "bottom":
          this.mode = "between";
          const top = element.getBoundingClientRect().top;
          this.position = "relative";
          this.top = top + scrollY - this.yOrigin + "px";
          this.transition = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)";
          this.opacity = 1;
          this.transform = "translateY(0) scale(1)";
          break;
      }
    } else if (scrollingDown && !isScrolledToBottom) {
      switch (this.mode) {
        case "between":
          if (isBottomInView(element, this.yOrigin)) {
            this.mode = "bottom";
            this.position = "fixed";
            this.bottom = 0;
            this.top = "unset";
            this.transition = "all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)";
            this.opacity = 1;
            this.transform = "translateY(0) scale(1)";
          }
          break;
        case "pinned":
        case "top":
          this.mode = "between";
          const top = element.getBoundingClientRect().top;
          this.position = "relative";
          this.top = top + scrollY - this.yOrigin;
          this.transition = "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)";
          this.opacity = 0.95;
          this.transform = "translateY(5px) scale(0.98)";
          break;
      }
    }
    this.prevScrollTop = scrollY;
  }

  @action
  didInsert(element) {
    this.element = element;
    this.offset = this.element.offsetTop;
    const headerElement = document.querySelector(".d-header");
    if (headerElement) {
      this.headerHeight = headerElement.offsetHeight;
    }

    // Add intersection observer for better performance
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.opacity = 1;
            this.transform = "translateY(0) scale(1)";
          } else {
            this.opacity = 0.8;
            this.transform = "translateY(10px) scale(0.95)";
          }
        });
      },
      {
        threshold: [0, 0.1, 0.5, 1],
        rootMargin: "50px",
      }
    );

    this.observer.observe(element);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  <template>
    <div class="sticky-sidebar">
      <div
        {{didInsert this.didInsert}}
        {{scroll this.onScroll}}
        style={{htmlSafe
          (concat
            "position: "
            this.position
            "; top: "
            this.top
            "; bottom: "
            this.bottom
            "; transition: "
            this.transition
            "; opacity: "
            this.opacity
            "; transform: "
            this.transform
            "; backdrop-filter: blur(10px);"
          )
        }}
        class="sticky-sidebar__content"
      >
        {{yield}}
      </div>
    </div>
  </template>
}
