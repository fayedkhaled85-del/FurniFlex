'use strict';
const advisorForm = document.getElementById('advisor-form');
function setAdvisorLoading(loading) {
  const results = document.getElementById('advisor-results');
  if (!results) return;
  results.classList.toggle('is-loading', loading);
  results.setAttribute('aria-busy', String(loading));
  document.getElementById('advisor-loading').hidden = !loading;
  document.getElementById('advisor-submit').disabled = loading;
  document.getElementById('advisor-status').textContent = loading ? 'Finding furniture for you…' : '';
}
advisorForm?.addEventListener('submit', () => {
  const disclosure = document.getElementById('advisor-disclosure-state');
  disclosure.value = document.getElementById('advisor-advanced').open ? '1' : '0';
  disclosure.disabled = false;
  setAdvisorLoading(true);
});
window.addEventListener('pageshow', () => setAdvisorLoading(false));
function syncExamples() {
  const value = document.getElementById('advisor-description').value.trim().toLowerCase();
  document.querySelectorAll('[data-advisor-example]').forEach(chip =>
    chip.setAttribute('aria-pressed', String(chip.dataset.advisorExample.toLowerCase() === value)));
}
document.getElementById('advisor-description')?.addEventListener('input', syncExamples);
if (advisorForm) syncExamples();
document.querySelectorAll('[data-advisor-example]').forEach(chip => {
  chip.addEventListener('click', () => {
    const description = document.getElementById('advisor-description');
    description.value = chip.dataset.advisorExample;
    syncExamples();
    description.focus();
  });
});
advisorForm?.addEventListener('invalid', event => {
  const details = event.target.closest('details');
  if (details) details.open = true;
}, true);

if (window.matchMedia('(max-width: 991px)').matches &&
    document.querySelector('#advisor-results .advisor-result, #advisor-results .advisor-message')) {
  document.getElementById('advisor-results').focus();
}

if (advisorForm && document.getElementById('advisor-apply-space')) {
  const numbers = [...advisorForm.querySelectorAll('[data-number]')];
  const dimensions = numbers.filter(input => !input.dataset.number.startsWith('budget'));
  const budgetMin = document.getElementById('advisor-budget_min');
  const budgetMax = document.getElementById('advisor-budget_max');
  const applySpace = document.getElementById('advisor-apply-space');
  const presets = [...advisorForm.querySelectorAll('[data-space-preset]')];
  const design = ['room', 'style', 'material', 'color'].map(key => document.getElementById('advisor-' + key));
  const summary = document.getElementById('advisor-filter-summary');

  function active(input, enabled) {
    if (enabled) input.name = input.dataset.number;
    else input.removeAttribute('name');
  }

  function refresh() {
    const labels = [];
    for (const input of numbers) {
      const group = input.closest('[data-number-control]');
      const value = input.valueAsNumber;
      const floor = dimensions.includes(input) ? 0.01 : 0;
      let message = '';
      input.setCustomValidity('');
      if (input.validity.badInput) message = 'Enter a number.';
      else if (input.validity.rangeOverflow || input.validity.rangeUnderflow) {
        message = floor ? 'Enter a measurement greater than zero and at most ' + input.max + ' cm.' : 'Enter a budget between zero and ' + input.max + ' dollars.';
      } else if (input.name && dimensions.includes(input) && value === 0) message = 'Enter a measurement greater than zero.';
      else if (input === budgetMax && budgetMin.name && input.name && budgetMin.valueAsNumber > value) {
        message = 'Maximum budget must be at least the minimum budget.';
      }
      input.setCustomValidity(message);
      input.setAttribute('aria-invalid', String(Boolean(message)));
      group.querySelector('[data-number-error]').textContent = message;
      group.querySelector('[data-number-state]').textContent = input.name ? 'Active' : (input.value ? 'Suggested' : 'No limit');
      for (const button of group.querySelectorAll('[data-adjust]')) {
        button.disabled = button.dataset.adjust === '1' ? value >= Number(input.max) : value <= floor;
      }
      if (input.name) labels.push(input.labels[0].textContent.split(' (')[0]);
    }
    const count = dimensions.filter(input => input.name).length;
    applySpace.checked = count === dimensions.length;
    applySpace.indeterminate = count > 0 && !applySpace.checked;
    for (const button of presets) {
      const values = JSON.parse(button.dataset.spacePreset);
      const selected = applySpace.checked && dimensions.every(input => input.valueAsNumber === values[input.dataset.number]);
      button.setAttribute('aria-pressed', String(selected));
      button.classList.toggle('active', selected);
    }
    for (const field of design) if (field.value) labels.push(field.value);
    summary.textContent = labels.length ? 'Active filters: ' + labels.join(', ') + '.' : 'No optional filters applied.';
  }

  // Add an integer to a decimal without binary floating-point rounding.
  function adjust(value, increment, floor, ceiling) {
    if (Number(value) === 0 || !Number.isFinite(Number(value))) value = '0';
    if (Number(value) < 0) value = '0';
    if (Number(value) > ceiling) value = String(ceiling);
    const [mantissa, exponent = '0'] = String(value).toLowerCase().split('e');
    const [whole, fraction = ''] = mantissa.split('.');
    const places = fraction.length - Number(exponent);
    const unit = 10n ** BigInt(Math.max(0, places));
    const scaled = BigInt(whole + fraction) * 10n ** BigInt(Math.max(0, -places)) + BigInt(increment) * unit;
    if (scaled <= 0n) return String(floor);
    if (scaled >= BigInt(ceiling) * unit) return String(ceiling);
    return places > 0 ? String(scaled / unit) + '.' + String(scaled % unit).padStart(places, '0') : String(scaled);
  }

  for (const input of numbers) {
    active(input, input.value !== '');
    if (!input.name) input.value = input.dataset.suggestion;
    input.addEventListener('input', () => {
      active(input, input.value !== '' || input.validity.badInput);
      refresh();
    });
    for (const button of input.closest('[data-number-control]').querySelectorAll('[data-adjust]')) {
      button.hidden = false;
      button.addEventListener('click', () => {
        input.value = adjust(input.value || input.dataset.suggestion, Number(input.dataset.step) * Number(button.dataset.adjust),
          dimensions.includes(input) ? 0.01 : 0, Number(input.max));
        active(input, true);
        refresh();
      });
    }
  }
  applySpace.addEventListener('change', () => {
    for (const input of dimensions) {
      if (!applySpace.checked || !input.value) input.value = input.dataset.suggestion;
      active(input, applySpace.checked && input.value !== '');
    }
    refresh();
  });
  for (const button of presets) button.addEventListener('click', () => {
    const values = JSON.parse(button.dataset.spacePreset);
    for (const input of dimensions) {
      input.value = values[input.dataset.number];
      active(input, true);
    }
    refresh();
  });
  design.forEach(field => field.addEventListener('input', refresh));
  document.getElementById('advisor-reset').addEventListener('click', event => {
    event.preventDefault();
    for (const input of numbers) { input.value = input.dataset.suggestion; active(input, false); }
    for (const input of design) input.value = '';
    document.getElementById('advisor-description').value = '';
    document.getElementById('advisor-outcome').replaceChildren();
    document.getElementById('advisor-empty').hidden = false;
    syncExamples();
    refresh();
    document.getElementById('advisor-description').focus();
  });
  advisorForm.querySelector('[data-enhanced]').hidden = false;
  refresh();
}
