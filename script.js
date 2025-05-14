/**
 * Handles the favicon based on the visibility of the page
 */
const faviconHandler = () => {
    const favicon = document.querySelector('link[rel="icon"][sizes="any"]');
    const faviconPath = document.hidden ? './favicon/favicon-inactive.svg' : './favicon/favicon.svg';
    favicon.setAttribute('href', faviconPath);
}

/**
 * Optimized smooth scroll handler
 */
const smoothScrollTo = (element) => {
    if (!element) return;

    // Use native smooth scroll with fallback
    if ('scrollBehavior' in document.documentElement.style) {
        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    } else {
        // Fallback for browsers that don't support smooth scroll
        window.scrollTo({
            top: element.offsetTop,
            behavior: 'smooth'
        });
    }
};

/**
 * Makes the page scroll to the target element
 * @returns {void}
 */
const hasChangerHandler = () => {
    const hash = window.location.hash;
    if (!hash) return;

    const element = document.querySelector(`a[href="${hash}"]`);
    if (!element) return;

    smoothScrollTo(element);
}

/**
 * Updates the active section based on the current scroll position
 */
const updateActiveSection = () => {
    // Cache selectors
    const activators = document.querySelectorAll('.heading-link-activator');
    const headingLinks = document.querySelectorAll('.heading-link');

    // Use requestAnimationFrame for better performance
    requestAnimationFrame(() => {
        let currentActivator = null;
        let maxVisibility = 0;

        // if use is at the top, remove active class from all links
        // and remove existing hash
        if (window.scrollY <= 50 && window.location.hash) {
            headingLinks.forEach(link => link.classList.remove('active'));
            history.replaceState(null, null, window.location.pathname);
            return;
        }

        // Consider using a more efficient loop
        for (let i = 0; i < activators.length; i++) {
            const activator = activators[i];
            const rect = activator.getBoundingClientRect();
            const visibility = Math.min(rect.bottom, window.innerHeight) - Math.max(rect.top, 0);

            if (visibility > maxVisibility) {
                maxVisibility = visibility;
                currentActivator = activator.querySelector("a[class='heading-link']");
                break;
            }
        }

        if (currentActivator) {
            const currentHref = currentActivator.getAttribute('href');

            // Consider using a Set for active links
            const currentHash = window.location.hash;
            if (currentHash !== currentHref) {
                history.replaceState(null, null, currentHref);

                // Update classes
                headingLinks.forEach(link => {
                    link.classList.toggle('active', link.getAttribute('href') === currentHref);
                });
            }
        }
    });
};

/**
 * Main function to handle all event listeners
 */
const main = () => {
    document.addEventListener('visibilitychange', faviconHandler);
    window.addEventListener('hashchange', hasChangerHandler);

    // Handle initial hash on page load
    if (window.location.hash) {
        requestAnimationFrame(() => {
            const targetElement = document.querySelector(`a[href="${window.location.hash}"]`);
            if (targetElement) {
                // Use RAF instead of setTimeout
                requestAnimationFrame(() => smoothScrollTo(targetElement));
            }
        });
    }

    let scrollTimeout;
    window.addEventListener('scroll', () => {
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(updateActiveSection, 100);
    }, { passive: true });
}

// Initialize once DOM is loaded
if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', main)
else main();