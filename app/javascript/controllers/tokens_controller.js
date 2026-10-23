import { Controller } from "@hotwired/stimulus"

// A multi-value filter shown as chips with ×. Every chip holds a hidden <input name="x[]">,
// so the form still submits plain GET params. Adding or removing a chip fires "change",
// which the filters controller turns into a submit.
//   - set-aside: pick from a <select> (entry target)
//   - FSC: type 4-digit codes (added as soon as 4 digits are typed) or click a quick pick
export default class extends Controller {
  static targets = ["list", "entry", "template", "pick"]
  static values = { name: String }

  connect() {
    this.refresh()
  }

  // <select> entry: add the chosen option, then reset the select to its placeholder
  choose() {
    const option = this.entryTarget.selectedOptions[0]
    if (option?.value) this.add(option.value, option.text)
    this.entryTarget.value = ""
  }

  // Text entry: every complete 4-digit code becomes a chip ("5305, 5310" can be pasted too)
  type() {
    const codes = this.entryTarget.value.match(/\d{4}/g) || []
    if (codes.length === 0) return
    codes.forEach((code) => this.add(code))
    this.entryTarget.value = ""
    this.changed()
  }

  // Enter must not submit the form; Backspace in an empty entry removes the last chip
  key(event) {
    if (event.key === "Enter") event.preventDefault()
    if (event.key === "Backspace" && this.entryTarget.value === "" && this.chips.length) {
      this.chips.at(-1).remove()
      this.changed()
    }
  }

  pickCode(event) {
    if (this.add(event.currentTarget.dataset.code)) this.changed()
  }

  remove(event) {
    event.currentTarget.closest(".token").remove()
    this.changed()
  }

  add(value, label = value) {
    if (!value || this.values.includes(value)) return false
    const chip = this.templateTarget.content.firstElementChild.cloneNode(true)
    chip.querySelector("[data-label]").textContent = label
    const input = chip.querySelector("input")
    input.name = this.nameValue
    input.value = value
    this.listTarget.append(chip)
    this.refresh()
    return true
  }

  changed() {
    this.refresh()
    this.element.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // Grey out what is already chosen (select options, quick-pick chips)
  refresh() {
    const chosen = this.values
    if (this.entryTarget.tagName === "SELECT") {
      for (const option of this.entryTarget.options) option.disabled = option.value !== "" && chosen.includes(option.value)
    }
    this.pickTargets.forEach((pick) => pick.classList.toggle("on", chosen.includes(pick.dataset.code)))
  }

  get chips() {
    return [...this.listTarget.querySelectorAll(".token")]
  }

  get values() {
    return this.chips.map((chip) => chip.querySelector("input").value)
  }
}
