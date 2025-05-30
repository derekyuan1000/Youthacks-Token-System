import { Application } from "@hotwired/stimulus"
import "@rails/ujs"

const application = Application.start()
Rails.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
