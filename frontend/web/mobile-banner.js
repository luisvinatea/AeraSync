(function() {
    // Only show on desktop when coming from mobile
    const urlParams = new URLSearchParams(window.location.search);
    const fromMobile = urlParams.get('from_mobile') === '1';
    
    if (fromMobile) {
      // Create banner
      const banner = document.createElement('div');
      banner.id = 'mobile-banner';
      banner.innerHTML = `
        <div class="banner-content">
          <p>Switch back to <a href="https://aerasync-mobile.vercel.app${window.location.pathname}">mobile version</a>?</p>
          <button id="close-banner">×</button>
        </div>
      `;
      
      // Style banner
      banner.style.cssText = `
        position: fixed;
        bottom: 0;
        left: 0;
        width: 100%;
        background-color: #1E40AF;
        color: white;
        z-index: 1000;
        padding: 12px;
        text-align: center;
        font-size: 14px;
      `;
      
      document.body.appendChild(banner);
      
      // Handle close
      document.getElementById('close-banner').addEventListener('click', function() {
        banner.style.display = 'none';
        localStorage.setItem('hideMobileBanner', '1');
      });
    }
  })();