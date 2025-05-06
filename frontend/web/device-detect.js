// /home/luisvinatea/DEVinatea/Repos/AeraSync/frontend/web/device-detect.js
(function() {
    // Check if device is mobile
    function isMobileDevice() {
      return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || 
             (window.innerWidth <= 767);
    }
    
    // Set cookie to remember preference
    function setDeviceCookie(mobile) {
      const d = new Date();
      d.setTime(d.getTime() + (7 * 24 * 60 * 60 * 1000)); // 7 days
      document.cookie = `preferMobileVersion=${mobile ? '1' : '0'};expires=${d.toUTCString()};path=/`;
    }
    
    // Get cookie value
    function getCookie(name) {
      const cookieArr = document.cookie.split(';');
      for (let i = 0; i < cookieArr.length; i++) {
        const cookiePair = cookieArr[i].split('=');
        if (name === cookiePair[0].trim()) {
          return decodeURIComponent(cookiePair[1]);
        }
      }
      return null;
    }
    
    // Check URL parameters
    const urlParams = new URLSearchParams(window.location.search);
    const forceDesktop = urlParams.get('desktop') === '1';
    const forceMobile = urlParams.get('mobile') === '1';
    
    // Remember preference
    if (forceDesktop) setDeviceCookie(false);
    if (forceMobile) setDeviceCookie(true);
    
    // Redirect to mobile if applicable
    const preferMobile = getCookie('preferMobileVersion') === '1';
    
    if ((isMobileDevice() || preferMobile) && !forceDesktop && window.location.hostname !== 'localhost') {
      const currentDomain = window.location.hostname;
      const mobileDomain = 'aerasync-mobile.vercel.app';
      
      if (currentDomain !== mobileDomain) {
        const mobileUrl = window.location.href.replace(currentDomain, mobileDomain);
        window.location.href = mobileUrl;
      }
    }
  })();