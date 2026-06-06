<template>
  <main class="policy">
    <article class="policy__sheet">
      <header class="policy__header">
        <h1 class="policy__title">Privacy Policy</h1>
        <p class="policy__meta">Last updated: {{ lastUpdated }}</p>
      </header>

      <section class="policy__section">
        <p>
          This Privacy Policy explains how {{ companyName }} ("we", "us", or "our")
          collects, uses, and protects your information when you use the
          {{ appName }} platform, including our web application, and our
          mobile applications (together, the "Service"). {{ appName }} is an
          agricultural monitoring and control platform that lets businesses monitor
          sensors, controllers, and connected devices across their sites and operate
          equipment remotely. By using the Service, you agree to this policy.
        </p>
      </section>

      <section class="policy__section">
        <h2>Information we collect</h2>

        <p>
          <strong>Account information.</strong> When you register or are invited, we
          collect your name and email address and store a securely hashed version of
          your password. We never store your password in plain text.
        </p>

        <p>
          <strong>Security and session data.</strong> To keep your account safe we
          process two-factor authentication codes and basic session details such as
          IP address, device and browser information, and sign-in timestamps.
        </p>

        <p>
          <strong>Organisation and site data.</strong> We store information about your
          company, your sites, and your equipment. Site records may include a name,
          country, city, time zone, and the geographic coordinates you enter to
          identify where your installation is located.
        </p>

        <p>
          <strong>Device and operational data.</strong> The core purpose of the
          Service is to collect and display data from your connected equipment,
          including sensor readings, controller and meter values, weather information
          for your sites, device status and settings, and the control actions you or
          your colleagues perform. We keep a history of this data and of configuration
          changes so the Service can provide monitoring, alerts, and analytics.
        </p>

        <p>
          <strong>Notifications and diagnostics.</strong> If you enable notifications,
          we use a device identifier to deliver them. We also collect limited
          technical diagnostic information when an error occurs, so we can fix
          problems and keep the Service reliable.
        </p>
      </section>

      <section class="policy__section">
        <h2>How we use your information</h2>
        <p>We use this information to:</p>
        <ul>
          <li>provide, operate, and maintain the Service;</li>
          <li>authenticate you and keep your account and data secure;</li>
          <li>display monitoring data, analytics, and historical trends;</li>
          <li>carry out and record the control actions you request;</li>
          <li>send alerts and essential account messages such as one-time codes and password resets;</li>
          <li>diagnose problems and improve the Service.</li>
        </ul>
        <p>
          We do not sell your information, and we do not use it for advertising.
        </p>
      </section>

      <section class="policy__section">
        <h2>How we share information</h2>
        <p>
          We share information only with the service providers who help us run the
          Service — for example, providers that host our systems, deliver
          notifications and emails, and help us monitor and fix technical problems.
          They may only use the information to provide those services to us. We may
          also disclose information if required by law or to protect our rights and
          the safety of others.
        </p>
      </section>

      <section class="policy__section">
        <h2>Data retention</h2>
        <p>
          We keep your account and operational data for as long as your account is
          active and as needed to provide the Service. When information is no longer
          needed, we delete or anonymise it, except where we are required to keep it
          to meet a legal obligation.
        </p>
      </section>

      <section class="policy__section">
        <h2>Security</h2>
        <p>
          We protect your data using encrypted connections, hashed passwords,
          encrypted storage for sensitive credentials, two-factor authentication, and
          access controls so users only see data for the sites and companies they are
          authorised to access. No method of transmission or storage is completely
          secure, but we work to protect your information using industry-standard
          measures.
        </p>
      </section>

      <section class="policy__section">
        <h2>Your rights and account deletion</h2>
        <p>
          You can access and update your information by signing in to your account.
          You can request deletion of your account and personal data at any time by
          emailing <a :href="`mailto:${contactEmail}`">{{ contactEmail }}</a> from the
          address linked to your account, or by using the in-app account deletion
          option where available. We will delete your information on a verified
          request, except for anything we are legally required to keep. If you are the
          last administrator of a company, you may need to transfer or close that
          organisation first.
        </p>
      </section>

      <section class="policy__section">
        <h2>Children</h2>
        <p>
          The Service is intended for business use. We do not specifically market it
          to children and do not knowingly collect personal information from children.
        </p>
      </section>

      <section class="policy__section">
        <h2>Cookies and local storage</h2>
        <p>
          The web application uses strictly necessary cookies and local storage to
          keep you signed in and remember basic preferences. Our mobile app stores
          authentication tokens in your device's secure storage. We do not use cookies
          for advertising or cross-site tracking.
        </p>
      </section>

      <section class="policy__section">
        <h2>Changes to this policy</h2>
        <p>
          We may update this policy from time to time. When we make material changes
          we will update the "Last updated" date above and, where appropriate, notify
          you through the Service.
        </p>
      </section>

      <section class="policy__section">
        <h2>Contact us</h2>
        <p>
          If you have any questions about this policy, please contact us:
        </p>
        <p class="policy__contact">
          {{ companyName }}<br />
          Email: <a :href="`mailto:${contactEmail}`">{{ contactEmail }}</a><br />
        </p>
      </section>
    </article>
  </main>
</template>

<script setup lang="ts">
  defineOptions({ layout: null })

  interface Props {
    appName?: string;
    companyName?: string;
    contactEmail?: string;
    lastUpdated?: string;
  };

  const {
    appName = 'FarmBits',
    companyName = 'FarmBits',
    contactEmail = 'support@farm-bits.com',
    lastUpdated = '6 June 2026'
  } = defineProps<Props>()
</script>

<style scoped>
  .policy {
    --policy-bg: #f4f6f8;
    --policy-sheet: #ffffff;
    --policy-text: #2c2c34;
    --policy-muted: #6b7280;
    --policy-heading: #15803d;
    --policy-link: #15803d;
    --policy-border: #e5e7eb;

    min-height: 100vh;
    margin: 0;
    padding: 2.5rem 1rem 4rem;
    background-color: var(--policy-bg);
    color: var(--policy-text);
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.65;
  }

  .policy__sheet {
    max-width: 860px;
    margin: 0 auto;
    padding: 2.75rem 2.5rem 3rem;
    background-color: var(--policy-sheet);
    border: 1px solid var(--policy-border);
    border-radius: 12px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
  }

  .policy__header {
    margin-bottom: 2rem;
    padding-bottom: 1.25rem;
    border-bottom: 1px solid var(--policy-border);
  }

  .policy__title {
    margin: 0 0 0.35rem;
    font-size: 2rem;
    font-weight: 700;
    letter-spacing: -0.01em;
  }

  .policy__meta {
    margin: 0;
    color: var(--policy-muted);
    font-size: 0.9rem;
  }

  .policy__section {
    margin-bottom: 1.75rem;
  }

  .policy__section h2 {
    margin: 0 0 0.6rem;
    font-size: 1.2rem;
    font-weight: 700;
    color: var(--policy-heading);
  }

  .policy__section p {
    margin: 0 0 0.85rem;
  }

  .policy__section ul {
    margin: 0 0 0.85rem;
    padding-left: 1.35rem;
  }

  .policy__section li {
    margin-bottom: 0.4rem;
  }

  .policy a {
    color: var(--policy-link);
    text-decoration: none;
    font-weight: 500;
  }

  .policy a:hover {
    text-decoration: underline;
  }

  .policy__contact {
    padding: 1rem 1.15rem;
    background-color: var(--policy-bg);
    border-radius: 8px;
  }

  @media (max-width: 640px) {
    .policy {
      padding: 1.25rem 0.75rem 3rem;
    }

    .policy__sheet {
      padding: 1.75rem 1.25rem 2.25rem;
    }

    .policy__title {
      font-size: 1.6rem;
    }
  }
</style>
