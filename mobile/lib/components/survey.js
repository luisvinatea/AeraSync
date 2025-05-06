export function initSurveyForm(app) {
  const surveyForm = document.getElementById("survey-form");
  const stepContainers = document.querySelectorAll(".survey-step");
  let currentStep = 0;

  // Initialize form with proper step visibility
  function initSteps() {
    stepContainers.forEach((step, index) => {
      step.style.display = index === currentStep ? "block" : "none";
    });
    updateNavButtons();
  }

  // Add event listeners to form buttons
  function setupNavButtons() {
    const nextBtn = document.getElementById("next-btn");
    const backBtn = document.getElementById("back-btn");
    const submitBtn = document.getElementById("submit-btn");

    if (nextBtn) {
      nextBtn.addEventListener("click", () => navigateStep(1));
    }

    if (backBtn) {
      backBtn.addEventListener("click", () => navigateStep(-1));
    }

    if (submitBtn) {
      submitBtn.addEventListener("click", submitForm);
    }
  }

  // Navigate between steps
  function navigateStep(direction) {
    if (direction === 1 && !validateCurrentStep()) {
      return;
    }

    const newStep = currentStep + direction;
    if (newStep >= 0 && newStep < stepContainers.length) {
      stepContainers[currentStep].style.display = "none";
      currentStep = newStep;
      stepContainers[currentStep].style.display = "block";
      updateNavButtons();
      updateProgressBar();
    }
  }

  // Update navigation buttons based on current step
  function updateNavButtons() {
    const nextBtn = document.getElementById("next-btn");
    const backBtn = document.getElementById("back-btn");
    const submitBtn = document.getElementById("submit-btn");

    if (backBtn) {
      backBtn.style.display = currentStep === 0 ? "none" : "block";
    }

    if (nextBtn) {
      nextBtn.style.display =
        currentStep === stepContainers.length - 1 ? "none" : "block";
    }

    if (submitBtn) {
      submitBtn.style.display =
        currentStep === stepContainers.length - 1 ? "block" : "none";
    }
  }

  // Update progress bar
  function updateProgressBar() {
    const progressBar = document.querySelector(".progress-bar");
    if (progressBar) {
      const progress = ((currentStep + 1) / stepContainers.length) * 100;
      progressBar.style.width = `${progress}%`;
    }
  }

  // Validate current form step
  function validateCurrentStep() {
    const currentStepEl = stepContainers[currentStep];
    const requiredFields = currentStepEl.querySelectorAll("[required]");
    let valid = true;

    requiredFields.forEach((field) => {
      if (!field.value) {
        field.classList.add("error");
        valid = false;
      } else {
        field.classList.remove("error");
      }
    });

    return valid;
  }

  // Submit the form
  async function submitForm(e) {
    e.preventDefault();

    if (!validateCurrentStep()) {
      return;
    }

    const formData = new FormData(surveyForm);
    const data = Object.fromEntries(formData.entries());

    // Show loading
    const submitBtn = document.getElementById("submit-btn");
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<span class="spinner"></span> Processing...';
    }

    try {
      await app.submitSurvey(data);
    } finally {
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = app.translations?.submit || "Submit";
      }
    }
  }

  // Initialize the component
  initSteps();
  setupNavButtons();
  updateProgressBar();
}
