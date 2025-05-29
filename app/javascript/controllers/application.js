import { Application } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

const application = Application.start()
Rails.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
