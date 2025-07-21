// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/dotuh"
import topbar from "../vendor/topbar"

console.log("🎤 app.js loading...")

// Fix mobile viewport height issues
function setViewportHeight() {
  const vh = window.innerHeight * 0.01
  document.documentElement.style.setProperty('--vh', `${vh}px`)
}

// Set initial viewport height
setViewportHeight()

// Update on resize and orientation change
window.addEventListener('resize', setViewportHeight)
window.addEventListener('orientationchange', () => {
  setTimeout(setViewportHeight, 100)
})

// Test Hook to verify hook system works
const TestHook = {
  mounted() {
    console.log("🔧 TestHook mounted successfully!")
  }
}

// Speech Recognition Hook
const SpeechRecognition = {
  mounted() {
    this.SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    this.recognition = null
    this.isListening = false
    this.speechButton = document.getElementById('speech-button')
    this.permissionGranted = false
    this.audioUnlocked = false
    
    console.log("🎤 SpeechRecognition hook mounted")
    console.log("🎤 Found speech button:", this.speechButton)
    
    // Check if browser supports speech recognition
    if (this.SpeechRecognition) {
      console.log("🎤 Speech recognition supported")
      
      // Check if we're on a secure context (required for mobile)
      const isLocalhost = window.location.hostname === 'localhost' || 
                         window.location.hostname === '127.0.0.1'
      
      const isSecure = window.isSecureContext || window.location.protocol === 'https:' || isLocalhost
      
      if (!isSecure) {
        console.warn("🎤 Speech recognition requires HTTPS on mobile devices")
        if (this.speechButton) {
          this.speechButton.classList.add('btn-disabled', 'opacity-50')
          this.speechButton.disabled = true
          this.speechButton.title = "Voice input requires HTTPS on mobile devices"
        }
      } else {
        this.checkMicrophonePermission()
      }
    } else {
      console.warn("🎤 Speech recognition not supported in this browser")
      if (this.speechButton) {
        this.speechButton.classList.add('btn-disabled', 'opacity-50')
        this.speechButton.disabled = true
        this.speechButton.title = "Speech recognition not supported on mobile"
      }
    }

    // Add click handler for speech button
    if (this.speechButton) {
      console.log("🎤 Adding click handler to speech button")
      
      // Only enable if not explicitly disabled above
      if (!this.speechButton.classList.contains('btn-disabled')) {
        this.speechButton.disabled = false
        this.speechButton.classList.remove('opacity-50')
      }
      
      this.speechButton.addEventListener('click', (event) => {
        console.log("🎤 Speech button clicked!")
        event.preventDefault()
        
        // Don't proceed if button is disabled
        if (this.speechButton.classList.contains('btn-disabled')) {
          console.log("🎤 Button is disabled, ignoring click")
          return
        }
        
        this.toggleSpeechRecognition()
      })
    } else {
      console.warn("🎤 Speech button not found!")
    }
    
    // Listen for global keyboard shortcut (Cmd+Shift+M for Mac)
    this.handleKeydown = (event) => {
      if (event.metaKey && event.shiftKey && event.code === 'KeyM') {
        event.preventDefault()
        this.toggleSpeechRecognition()
      }
    }
    
    document.addEventListener('keydown', this.handleKeydown)
  },

  async checkMicrophonePermission() {
    try {
      if (navigator.permissions && navigator.permissions.query) {
        const permission = await navigator.permissions.query({ name: 'microphone' })
        console.log("🎤 Microphone permission status:", permission.state)
        
        if (permission.state === 'granted') {
          this.permissionGranted = true
          if (this.speechButton) {
            this.speechButton.title = "Click to speak"
          }
        } else if (permission.state === 'denied') {
          this.handlePermissionDenied()
        }
        
        // Listen for permission changes
        permission.onchange = () => {
          console.log("🎤 Permission changed to:", permission.state)
          if (permission.state === 'granted') {
            this.permissionGranted = true
            this.updateUI()
          } else if (permission.state === 'denied') {
            this.handlePermissionDenied()
          }
        }
      }
    } catch (e) {
      console.log("🎤 Permission API not available, will request on first use")
    }
  },

  handlePermissionDenied() {
    console.warn("🎤 Microphone permission denied")
    if (this.speechButton) {
      this.speechButton.classList.add('btn-disabled', 'opacity-50')
      this.speechButton.disabled = true
      this.speechButton.title = "Microphone permission denied"
    }
  },

  showPermissionPrompt() {
    // Show user-friendly message
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-red-500 text-white p-4 rounded shadow-lg z-50'
    notification.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
        </svg>
        <div>
          <div class="font-bold">Microphone Permission Required</div>
          <div class="text-sm">Please enable microphone access in your browser settings</div>
        </div>
      </div>
    `
    document.body.appendChild(notification)
    
    // Remove after 5 seconds
    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification)
      }
    }, 5000)
  },
  
  updateUI() {
    console.log("🎤 updateUI called, isListening:", this.isListening)
    const textInput = this.el.querySelector('input[name*="text"]')
    const speechButton = this.speechButton
    
    console.log("🎤 textInput found:", !!textInput)
    console.log("🎤 speechButton found:", !!speechButton)
    
    if (this.isListening) {
      // Listening state
      textInput?.setAttribute('placeholder', 'Listening... speak now!')
      if (speechButton) {
        speechButton.classList.add('btn-error', 'animate-pulse')
        speechButton.classList.remove('btn-ghost')
        speechButton.innerHTML = '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><circle cx="10" cy="10" r="8"/></svg>'
        speechButton.title = 'Click to stop listening'
      }
    } else {
      // Not listening state
      textInput?.setAttribute('placeholder', 'Type your message...')
      if (speechButton) {
        speechButton.classList.remove('btn-error', 'animate-pulse')
        speechButton.classList.add('btn-ghost')
        speechButton.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path></svg>'
        speechButton.title = 'Click to speak (or Cmd+Shift+M)'
      }
    }
  },
  
  createNewRecognition() {
    if (!this.SpeechRecognition) {
      return null
    }
    
    console.log("🎤 Creating new speech recognition instance")
    const recognition = new this.SpeechRecognition()
    
    recognition.continuous = false
    recognition.interimResults = false
    recognition.lang = 'en-US'
    
    recognition.onstart = () => {
      console.log("🎤 Speech recognition started")
      this.isListening = true
      this.updateUI()
    }
    
    recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript
      console.log("🎤 Speech recognized:", transcript)
      
      // Fill the text input
      const textInput = this.el.querySelector('input[name*="text"]')
      if (textInput) {
        textInput.value = transcript
        textInput.dispatchEvent(new Event('input', { bubbles: true }))
        
        // Auto-submit the form after speech recognition
        console.log("🎤 Auto-submitting form with speech input")
        this.el.dispatchEvent(new Event('submit', { bubbles: true }))
      }
    }
    
    recognition.onend = () => {
      console.log("🎤 Speech recognition ended")
      this.isListening = false
      this.recognition = null // Clear the reference
      this.updateUI()
    }
    
    recognition.onerror = (event) => {
      console.error("🎤 Speech recognition error:", event.error)
      this.isListening = false
      this.recognition = null // Clear the reference
      
      if (event.error === 'not-allowed') {
        this.handlePermissionDenied()
        this.showPermissionPrompt()
      }
      
      this.updateUI()
    }
    
    return recognition
  },

  toggleSpeechRecognition() {
    console.log("🎤 toggleSpeechRecognition called, isListening:", this.isListening)
    
    if (!this.SpeechRecognition) {
      console.warn("🎤 Speech recognition not available")
      return
    }
    
    // Unlock audio playback by playing a silent audio element
    if (!this.audioUnlocked) {
      try {
        const silentAudio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmweAzmB0fO9AJU=')
        silentAudio.play().then(() => {
          console.log("🎵 Audio unlocked via speech button")
          this.audioUnlocked = true
        }).catch(() => {
          console.log("🎵 Failed to unlock audio")
        })
      } catch (e) {
        console.log("🎵 Could not create unlock audio")
      }
    }
    
    if (this.isListening && this.recognition) {
      console.log("🎤 Stopping speech recognition")
      this.recognition.stop()
    } else {
      console.log("🎤 Starting speech recognition")
      try {
        // Create a fresh recognition instance each time
        this.recognition = this.createNewRecognition()
        if (this.recognition) {
          this.recognition.start()
        }
      } catch (e) {
        console.error("🎤 Error starting speech recognition:", e)
        this.isListening = false
        this.recognition = null
        this.updateUI()
      }
    }
  },
  
  destroyed() {
    if (this.recognition) {
      this.recognition.stop()
    }
    document.removeEventListener('keydown', this.handleKeydown)
  }
}

// Audio Controller Hook to manage stop button visibility
const AudioController = {
  mounted() {
    this.audioElement = document.getElementById('tts-audio')
    this.stopButton = document.getElementById('stop-audio-button')
    
    console.log("🎵 AudioController: Hook mounted")
    
    if (this.audioElement) {
      // Show stop button when audio starts playing
      this.audioElement.addEventListener('play', () => {
        console.log("🎵 AudioController: Audio started playing, showing stop button")
        if (this.stopButton) {
          this.stopButton.style.display = 'inline-flex'
        }
      })
      
      // Hide stop button when audio ends or is paused
      this.audioElement.addEventListener('pause', () => {
        console.log("🎵 AudioController: Audio paused, hiding stop button")
        if (this.stopButton) {
          this.stopButton.style.display = 'none'
        }
      })
      
      this.audioElement.addEventListener('ended', () => {
        console.log("🎵 AudioController: Audio ended, hiding stop button")
        if (this.stopButton) {
          this.stopButton.style.display = 'none'
        }
      })
    }
  },
  
  destroyed() {
    console.log("🎵 AudioController: Hook destroyed")
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, SpeechRecognition, TestHook, AudioController},
})

console.log("🎤 Available hooks:", Object.keys({...colocatedHooks, SpeechRecognition, TestHook, AudioController}))

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

