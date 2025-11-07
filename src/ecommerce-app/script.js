// E-Commerce Application JavaScript
let products = [];
let cart = [];
let currentFilter = 'all';

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    console.log('CloudMart E-Commerce Application Started');
    
    // Load products
    loadProducts();
    
    // Set up event listeners
    setupEventListeners();
    
    // Initialize deployment info
    updateDeploymentInfo();
    
    // Set up health check
    setupHealthCheck();
    
    // Load cart from localStorage
    loadCartFromStorage();
});

// Load products data
async function loadProducts() {
    try {
        // Try to load from products.json file
        const response = await fetch('products.json');
        if (response.ok) {
            products = await response.json();
        } else {
            // Fallback to hardcoded products
            products = getDefaultProducts();
        }
        
        displayProducts();
    } catch (error) {
        console.log('Loading default products due to:', error.message);
        products = getDefaultProducts();
        displayProducts();
    }
}

// Default products data
function getDefaultProducts() {
    return [
        {
            id: 1,
            name: "AWS Cloud Practitioner Guide",
            category: "books",
            price: 29.99,
            description: "Complete guide to AWS Cloud Practitioner certification",
            icon: "fas fa-book"
        },
        {
            id: 2,
            name: "DevOps Toolkit",
            category: "electronics",
            price: 199.99,
            description: "Essential tools for modern DevOps practices",
            icon: "fas fa-tools"
        },
        {
            id: 3,
            name: "Cloud Engineer T-Shirt",
            category: "clothing",
            price: 24.99,
            description: "Comfortable t-shirt for cloud engineers",
            icon: "fas fa-tshirt"
        },
        {
            id: 4,
            name: "Kubernetes Handbook",
            category: "books",
            price: 34.99,
            description: "Master container orchestration with Kubernetes",
            icon: "fas fa-book-open"
        },
        {
            id: 5,
            name: "CI/CD Pipeline Laptop",
            category: "electronics",
            price: 899.99,
            description: "High-performance laptop for development",
            icon: "fas fa-laptop"
        },
        {
            id: 6,
            name: "Docker Hoodie",
            category: "clothing",
            price: 39.99,
            description: "Warm hoodie with Docker logo",
            icon: "fas fa-user-tie"
        },
        {
            id: 7,
            name: "Terraform Guide",
            category: "books",
            price: 32.99,
            description: "Infrastructure as Code with Terraform",
            icon: "fas fa-code"
        },
        {
            id: 8,
            name: "Monitoring Dashboard",
            category: "electronics",
            price: 299.99,
            description: "Real-time monitoring solution",
            icon: "fas fa-chart-line"
        }
    ];
}

// Display products
function displayProducts() {
    const productsGrid = document.getElementById('productsGrid');
    const filteredProducts = currentFilter === 'all' 
        ? products 
        : products.filter(product => product.category === currentFilter);
    
    productsGrid.innerHTML = filteredProducts.map(product => `
        <div class="product-card" data-category="${product.category}">
            <div class="product-image">
                <i class="${product.icon}"></i>
            </div>
            <div class="product-info">
                <h3>${product.name}</h3>
                <p>${product.description}</p>
                <div class="product-price">$${product.price.toFixed(2)}</div>
                <button class="add-to-cart" onclick="addToCart(${product.id})">
                    <i class="fas fa-cart-plus"></i> Add to Cart
                </button>
            </div>
        </div>
    `).join('');
}

// Setup event listeners
function setupEventListeners() {
    // Navigation
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Update active nav link
            navLinks.forEach(l => l.classList.remove('active'));
            this.classList.add('active');
            
            // Scroll to section
            const targetId = this.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            if (targetSection) {
                targetSection.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
    
    // Filter buttons
    const filterBtns = document.querySelectorAll('.filter-btn');
    filterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            // Update active filter
            filterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            
            // Update current filter and display products
            currentFilter = this.getAttribute('data-category');
            displayProducts();
        });
    });
    
    // Search functionality
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('input', function() {
        const searchTerm = this.value.toLowerCase();
        const productCards = document.querySelectorAll('.product-card');
        
        productCards.forEach(card => {
            const productName = card.querySelector('h3').textContent.toLowerCase();
            const productDesc = card.querySelector('p').textContent.toLowerCase();
            
            if (productName.includes(searchTerm) || productDesc.includes(searchTerm)) {
                card.style.display = 'block';
            } else {
                card.style.display = 'none';
            }
        });
    });
    
    // Contact form
    const contactForm = document.getElementById('contactForm');
    contactForm.addEventListener('submit', function(e) {
        e.preventDefault();
        showNotification('Thank you for your message! We\'ll get back to you soon.', 'success');
        this.reset();
    });
}

// Add product to cart
function addToCart(productId) {
    const product = products.find(p => p.id === productId);
    if (!product) return;
    
    const existingItem = cart.find(item => item.id === productId);
    
    if (existingItem) {
        existingItem.quantity += 1;
    } else {
        cart.push({
            ...product,
            quantity: 1
        });
    }
    
    updateCartDisplay();
    saveCartToStorage();
    showNotification(`${product.name} added to cart!`, 'success');
}

// Remove from cart
function removeFromCart(productId) {
    cart = cart.filter(item => item.id !== productId);
    updateCartDisplay();
    saveCartToStorage();
}

// Update cart quantity
function updateCartQuantity(productId, change) {
    const item = cart.find(item => item.id === productId);
    if (!item) return;
    
    item.quantity += change;
    
    if (item.quantity <= 0) {
        removeFromCart(productId);
    } else {
        updateCartDisplay();
        saveCartToStorage();
    }
}

// Update cart display
function updateCartDisplay() {
    const cartCount = document.getElementById('cartCount');
    const cartItems = document.getElementById('cartItems');
    const cartTotal = document.getElementById('cartTotal');
    
    // Update cart count
    const totalItems = cart.reduce((sum, item) => sum + item.quantity, 0);
    cartCount.textContent = totalItems;
    
    // Update cart items
    if (cart.length === 0) {
        cartItems.innerHTML = '<p style="text-align: center; color: #666; padding: 20px;">Your cart is empty</p>';
    } else {
        cartItems.innerHTML = cart.map(item => `
            <div class="cart-item">
                <div class="cart-item-image">
                    <i class="${item.icon}"></i>
                </div>
                <div class="cart-item-info">
                    <h4>${item.name}</h4>
                    <div class="cart-item-price">$${item.price.toFixed(2)}</div>
                    <div class="cart-item-quantity">
                        <button class="quantity-btn" onclick="updateCartQuantity(${item.id}, -1)">-</button>
                        <span>${item.quantity}</span>
                        <button class="quantity-btn" onclick="updateCartQuantity(${item.id}, 1)">+</button>
                        <button class="quantity-btn" onclick="removeFromCart(${item.id})" style="margin-left: 10px; color: #dc3545;">×</button>
                    </div>
                </div>
            </div>
        `).join('');
    }
    
    // Update total
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    cartTotal.textContent = total.toFixed(2);
}

// Toggle cart sidebar
function toggleCart() {
    const cartSidebar = document.getElementById('cartSidebar');
    cartSidebar.classList.toggle('open');
}

// Checkout function
function checkout() {
    if (cart.length === 0) {
        showNotification('Your cart is empty!', 'warning');
        return;
    }
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    showNotification(`Checkout successful! Total: $${total.toFixed(2)}`, 'success');
    
    // Clear cart
    cart = [];
    updateCartDisplay();
    saveCartToStorage();
    toggleCart();
}

// Scroll to products section
function scrollToProducts() {
    document.getElementById('products').scrollIntoView({ behavior: 'smooth' });
}

// Save cart to localStorage
function saveCartToStorage() {
    localStorage.setItem('cloudmart-cart', JSON.stringify(cart));
}

// Load cart from localStorage
function loadCartFromStorage() {
    const savedCart = localStorage.getItem('cloudmart-cart');
    if (savedCart) {
        cart = JSON.parse(savedCart);
        updateCartDisplay();
    }
}

// Update deployment information
function updateDeploymentInfo() {
    const deploymentTime = document.getElementById('deploymentTime');
    const lastDeployment = document.getElementById('lastDeployment');
    const buildVersion = document.getElementById('buildVersion');
    const environment = document.getElementById('environment');
    
    const now = new Date();
    const timeString = now.toLocaleString();
    
    if (deploymentTime) {
        deploymentTime.textContent = `(${timeString})`;
    }
    
    if (lastDeployment) {
        lastDeployment.textContent = timeString;
    }
    
    if (buildVersion) {
        // Generate a version number based on current time
        const version = `v1.${now.getMonth() + 1}.${now.getDate()}`;
        buildVersion.textContent = version;
    }
    
    if (environment) {
        environment.textContent = 'Production';
    }
}

// Setup health check
function setupHealthCheck() {
    const healthMessage = document.getElementById('health-message');
    const healthTimestamp = document.getElementById('health-timestamp');
    
    if (healthMessage) {
        healthMessage.textContent = 'OK';
    }
    
    if (healthTimestamp) {
        healthTimestamp.textContent = new Date().toISOString();
    }
    
    // Update health check every 30 seconds
    setInterval(() => {
        if (healthTimestamp) {
            healthTimestamp.textContent = new Date().toISOString();
        }
    }, 30000);
}

// Show notification
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${getNotificationIcon(type)}"></i>
            <span>${message}</span>
        </div>
        <button class="notification-close">&times;</button>
    `;
    
    // Add styles
    notification.style.cssText = `
        position: fixed;
        top: 90px;
        right: 20px;
        background: ${getNotificationColor(type)};
        color: white;
        padding: 15px 20px;
        border-radius: 10px;
        box-shadow: 0 5px 20px rgba(0,0,0,0.2);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: space-between;
        min-width: 300px;
        transform: translateX(100%);
        transition: transform 0.3s ease;
    `;
    
    // Add to page
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
        notification.style.transform = 'translateX(0)';
    }, 100);
    
    // Handle close button
    const closeBtn = notification.querySelector('.notification-close');
    closeBtn.addEventListener('click', () => {
        removeNotification(notification);
    });
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        removeNotification(notification);
    }, 5000);
}

// Remove notification
function removeNotification(notification) {
    notification.style.transform = 'translateX(100%)';
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 300);
}

// Get notification icon
function getNotificationIcon(type) {
    const icons = {
        success: 'check-circle',
        error: 'exclamation-circle',
        warning: 'exclamation-triangle',
        info: 'info-circle'
    };
    return icons[type] || 'info-circle';
}

// Get notification color
function getNotificationColor(type) {
    const colors = {
        success: '#28a745',
        error: '#dc3545',
        warning: '#ffc107',
        info: '#17a2b8'
    };
    return colors[type] || '#17a2b8';
}

// Performance monitoring
function monitorPerformance() {
    // Monitor page load time
    window.addEventListener('load', function() {
        const loadTime = performance.now();
        console.log(`Page loaded in ${loadTime.toFixed(2)}ms`);
        
        // Send metrics (in real app, this would go to monitoring service)
        if (loadTime > 3000) {
            console.warn('Slow page load detected');
        }
    });
}

// Initialize performance monitoring
monitorPerformance();

// Error handling
window.addEventListener('error', function(e) {
    console.error('Application error:', e.error);
    showNotification('An error occurred. Please refresh the page if issues persist.', 'error');
});

// Health check endpoint for load balancer
window.healthCheck = function() {
    return {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        uptime: performance.now(),
        cart_items: cart.length,
        products_loaded: products.length
    };
};

// Export functions for testing (if needed)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        addToCart,
        removeFromCart,
        updateCartQuantity,
        showNotification
    };
}
