// One submit per form: after the first click (or Enter) the button shows a spinner and further
// submits are ignored, so a slow "Create account" can't post twice. Runs on every page of the theme.
(() => {
  // keycloak.v2 renders some submits as <input type="submit">, which can't hold a spinner;
  // swap them for an equivalent <button> (same attributes, so the same name/value is posted)
  document.querySelectorAll('.gtn input[type="submit"]').forEach((input) => {
    const button = document.createElement('button')
    for (const attr of input.attributes) button.setAttribute(attr.name, attr.value)
    button.type = 'submit'
    button.textContent = input.value
    input.replaceWith(button)
  })

  // Bubble phase on document: runs after the form's own handlers, so a form that cancels
  // its submit (validation) is not locked
  document.addEventListener('submit', (event) => {
    const form = event.target
    if (!(form instanceof HTMLFormElement) || !form.closest('.gtn')) return
    if (form.dataset.gtnBusy) {
      event.preventDefault()
      return
    }
    if (event.defaultPrevented) return
    form.dataset.gtnBusy = 'true'

    // Not `disabled`: that would drop the clicked button's name/value from the post
    form.querySelectorAll('[type="submit"]').forEach((button) => button.setAttribute('aria-disabled', 'true'))
    const clicked = event.submitter || form.querySelector('[type="submit"]')
    if (clicked && clicked.tagName === 'BUTTON') {
      clicked.classList.add('gtn-busy')
      clicked.setAttribute('aria-busy', 'true')
      const spinner = document.createElement('span')
      spinner.className = 'gtn-spinner'
      spinner.setAttribute('aria-hidden', 'true')
      clicked.prepend(spinner)
    }
  })

  // Back button restores the page from cache with the spinner still on; unlock it
  window.addEventListener('pageshow', (event) => {
    if (!event.persisted) return
    document.querySelectorAll('.gtn form[data-gtn-busy]').forEach((form) => {
      delete form.dataset.gtnBusy
      form.querySelectorAll('[type="submit"]').forEach((button) => {
        button.removeAttribute('aria-disabled')
        button.removeAttribute('aria-busy')
        button.classList.remove('gtn-busy')
        button.disabled = false
      })
      form.querySelectorAll('.gtn-spinner').forEach((spinner) => spinner.remove())
    })
  })
})()
