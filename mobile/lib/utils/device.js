export const detectDeviceType = () => {
  const ua = navigator.userAgent;
  if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
    return "tablet";
  }
  if (
    /Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(
      ua
    )
  ) {
    return "mobile";
  }
  return "desktop";
};

export const applyDeviceOptimizations = () => {
  const deviceType = detectDeviceType();

  // Add device type as class to body
  document.body.classList.add(deviceType);

  if (deviceType === "mobile") {
    // Fix viewport height for mobile
    const vh = window.innerHeight * 0.01;
    document.documentElement.style.setProperty("--vh", `${vh}px`);

    // Listen for resize/orientation change
    window.addEventListener("resize", () => {
      const vh = window.innerHeight * 0.01;
      document.documentElement.style.setProperty("--vh", `${vh}px`);
    });

    // Disable hover effects on mobile
    document.body.classList.add("no-hover");
  }
};
