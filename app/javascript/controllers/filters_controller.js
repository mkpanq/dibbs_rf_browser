import { Controller } from "@hotwired/stimulus"

// Submits the filter form as soon as something changes; text fields wait for a pause in typing.
// A form that hasn't changed since the last submit is not sent again (no duplicate DB queries).
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  connect() {
    this.last = this.serialize()
  }

  debounce() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.submit(), this.delayValue)
  }

  submit() {
    clearTimeout(this.timer)
    if (this.serialize() === this.last) return
    this.element.requestSubmit()
  }

  // Also called for Enter in the search box (native submit)
  remember() {
    clearTimeout(this.timer)
    this.last = this.serialize()
  }

  serialize() {
    return new URLSearchParams(new FormData(this.element)).toString()
  }
}
