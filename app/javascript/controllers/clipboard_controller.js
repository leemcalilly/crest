import { Controller } from "@hotwired/stimulus"

// Copy one prompt, and say so. Silent copying leaves people clicking twice.
export default class extends Controller {
  static values = { text: String }
  static targets = ["label"]

  copy() {
    this.write(this.textValue)
      .then(() => this.say("Copied"))
      .catch(() => this.say("Press ⌘C"))
  }

  async write(text) {
    if (navigator.clipboard?.writeText) return navigator.clipboard.writeText(text)

    // Older browsers, and any page not served over HTTPS.
    const field = document.createElement("textarea")
    field.value = text
    field.setAttribute("readonly", "")
    field.style.position = "fixed"
    field.style.opacity = "0"
    document.body.appendChild(field)
    field.select()
    const ok = document.execCommand("copy")
    field.remove()
    if (!ok) throw new Error("copy refused")
  }

  say(message) {
    if (!this.hasLabelTarget) return
    const original = this.labelTarget.dataset.original || this.labelTarget.textContent
    this.labelTarget.dataset.original = original
    this.labelTarget.textContent = message
    this.element.classList.add("copied")

    clearTimeout(this.resetAt)
    this.resetAt = setTimeout(() => {
      this.labelTarget.textContent = original
      this.element.classList.remove("copied")
    }, 1600)
  }
}
