import { library, dom } from '@fortawesome/fontawesome-svg-core'
import { faOrcid } from '@fortawesome/free-brands-svg-icons'

// Add brand icons to our library
library.add(faOrcid)

// Replace any existing <i> tags with <svg> and set up a MutationObserver to
// continue doing this as the DOM changes.
dom.watch()
