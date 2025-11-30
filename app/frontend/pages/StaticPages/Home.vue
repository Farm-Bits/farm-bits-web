<template>
  <div class="page-container">
    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-overlay"></div>
      <CContainer class="hero-container">
        <div class="hero-content">
          <h1 class="hero-title">
            Transform Agriculture
            <span class="block">Effortlessly</span>
          </h1>
          <p class="hero-subtitle">
            Revolutionize your farming methods with seamless smart technology solutions.
            Experience growth and efficiency like never before.
          </p>
          <div class="hero-buttons">
            <CButton class="btn-primary" @click="router.visit(paths.pages.signUp)">
              Get Started Free
            </CButton>
          </div>
        </div>
      </CContainer>
    </section>

    <!-- Features Grid -->
    <section class="section">
      <CContainer class="px-4">
        <div class="section-header">
          <h2 class="section-title">Why Choose Farm Bits?</h2>
          <p class="section-subtitle">
            Cutting-edge technology meets agricultural expertise to deliver unprecedented results
          </p>
        </div>

        <div class="feature-grid">
          <div class="feature-card">
            <div class="feature-icon-green">
              <svg class="feature-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
              </svg>
            </div>
            <h3 class="feature-title">Increase Productivity</h3>
            <p class="feature-description">
              Optimize your operations with real-time data and AI-powered insights to boost yields by up to 30%.
            </p>
          </div>

          <div class="feature-card">
            <div class="feature-icon-blue">
              <svg class="feature-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
              </svg>
            </div>
            <h3 class="feature-title">Smart Analytics</h3>
            <p class="feature-description">
              Get detailed insights into soil conditions, weather patterns, and crop health with our advanced monitoring system.
            </p>
          </div>

          <div class="feature-card">
            <div class="w-16 h-16 rounded-2xl flex items-center justify-center mb-6" style="background: var(--feature-purple-color);">
              <svg class="feature-icon-svg" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <h3 class="feature-title">24/7 Monitoring</h3>
            <p class="feature-description">
              Never miss critical moments with round-the-clock monitoring and instant alerts delivered to your mobile device.
            </p>
          </div>
        </div>

        <!-- Main Feature Cards -->
        <div class="grid md:grid-cols-2 gap-8">
          <div class="feature-large-card-green">
            <div class="feature-large-content">
              <h3 class="feature-large-title">Precision Agriculture</h3>
              <p class="feature-large-description text-green-100">
                Harness the power of IoT sensors, satellite imagery, and machine learning to make data-driven decisions that maximize your farm's potential.
              </p>
              <CButton variant="outline" class="border-2 border-white text-white hover:bg-white hover:text-brand-green font-semibold">
                Learn More
              </CButton>
            </div>
          </div>
          <div class="feature-large-card-blue">
            <div class="feature-large-content">
              <h3 class="feature-large-title">Sustainable Solutions</h3>
              <p class="feature-large-description text-blue-100">
                Reduce environmental impact while increasing profitability. Our eco-friendly approach helps you farm smarter, not harder.
              </p>
              <CButton variant="outline" class="border-2 border-white text-white hover:bg-white hover:text-brand-blue font-semibold">
                Discover More
              </CButton>
            </div>
          </div>
        </div>
      </CContainer>
    </section>

    <!-- CTA Section -->
    <section class="section">
      <CContainer class="px-4">
        <div class="cta-card">
          <h2 class="cta-title">Ready to Transform Your Farm?</h2>
          <p class="cta-subtitle">
            Join thousands of farmers who have already revolutionized their operations with Farm Bits.
          </p>
          <div class="cta-buttons">
            <CButton class="btn-primary" @click="router.visit(paths.pages.signUp)">
              Start Free Trial
            </CButton>
            <CButton href="/contact" class="btn-secondary">
              Contact Sales
            </CButton>
          </div>
        </div>
      </CContainer>
    </section>
  </div>
</template>

<script lang="ts" setup>
  import { router } from '@inertiajs/vue3';
  import useAuth from '@/composables/useAuth';

  const { paths } = useAuth();
</script>

<style scoped>
</style>
