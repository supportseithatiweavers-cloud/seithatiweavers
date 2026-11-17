import { useState } from "react";
import {
  callToActionImage,
  categories,
  categoryShowcases,
  craftSteps,
  storyImage,
} from "../models/crafts.js";
import { contactDetails } from "../models/contact.js";
import seithatiLogo from "../assets/seithati-weavers-logo.png";

const heroImage =
  "https://images.unsplash.com/photo-1600166898405-da9535204843?auto=format&fit=crop&w=2000&q=90";

export function Announcement({ text }) {
  return <div className="announcement">{text}</div>;
}

function LanguageFlag({ language }) {
  if (language === "st") {
    return (
      <svg className="language-flag" viewBox="0 0 30 20" aria-hidden="true">
        <rect width="30" height="20" rx="2" fill="#fff" />
        <path d="M1 1h28v5H1z" fill="#00209f" />
        <path d="M1 14h28v5H1z" fill="#009543" />
        <path
          d="M15 5.2c-2.7 0-4.8 2.2-4.8 4.8v3.8h9.6V10c0-2.6-2.1-4.8-4.8-4.8Z"
          fill="#111"
        />
        <path d="M12.1 8.2h5.8M11.5 10h7" stroke="#fff" strokeWidth="1" />
      </svg>
    );
  }

  return (
    <svg className="language-flag" viewBox="0 0 30 20" aria-hidden="true">
      <rect width="30" height="20" rx="2" fill="#012169" />
      <path d="m0 0 30 20M30 0 0 20" stroke="#fff" strokeWidth="4.5" />
      <path d="m0 0 30 20M30 0 0 20" stroke="#c8102e" strokeWidth="1.8" />
      <path d="M15 0v20M0 10h30" stroke="#fff" strokeWidth="7" />
      <path d="M15 0v20M0 10h30" stroke="#c8102e" strokeWidth="3.2" />
    </svg>
  );
}

export function LanguageSelect({ language, onChange, label }) {
  const [open, setOpen] = useState(false);
  const choices = [
    { code: "en", name: "English" },
    { code: "st", name: "Sesotho" },
  ];
  const selected = choices.find((choice) => choice.code === language) ?? choices[0];

  return (
    <div className="language-dropdown">
      <button
        type="button"
        className="language-dropdown-trigger"
        aria-label={label}
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
        onKeyDown={(event) => {
          if (event.key === "Escape") setOpen(false);
        }}
      >
        <LanguageFlag language={selected.code} />
        <span>{selected.name}</span>
        <span className="language-chevron" aria-hidden="true" />
      </button>
      {open && (
        <div className="language-dropdown-options" role="listbox" aria-label={label}>
          {choices.map((choice) => (
            <button
              type="button"
              role="option"
              aria-selected={choice.code === language}
              className={
                choice.code === language
                  ? "language-dropdown-option is-selected"
                  : "language-dropdown-option"
              }
              key={choice.code}
              onClick={() => {
                onChange(choice.code);
                setOpen(false);
              }}
            >
              <LanguageFlag language={choice.code} />
              <span>{choice.name}</span>
              {choice.code === language && (
                <span className="language-check" aria-hidden="true">
                  ✓
                </span>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export function Header({ language, setLanguage, t, currentPage }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const navigation = [
    [t.navigation.home, "/", "home"],
    [t.navigation.crafts, "/crafts", "crafts"],
    [t.navigation.story, "/story", "story"],
    [t.navigation.craft, "/process", "process"],
    [t.navigation.contact, "/contact", "contact"],
    [t.navigation.personalizedCrafts, "/personalized-crafts", "personalized-crafts"],
    [t.navigation.chat, "/customer-chat", "customer-chat"],
  ];

  return (
    <header className="site-header">
      <div className="header-inner">
        <a className="brand" href="/" aria-label="Seithati Weavers home">
          <img className="brand-logo" src={seithatiLogo} alt="" />
          <span>
            <strong>Seithati</strong>
            <small>{t.brandSmall}</small>
          </span>
        </a>
        <nav className="desktop-nav" aria-label="Main navigation">
          {navigation.map(([label, href, page]) => (
            <a
              key={href}
              href={href}
              className={currentPage === page ? "is-active" : undefined}
              aria-current={currentPage === page ? "page" : undefined}
            >
              {label}
            </a>
          ))}
        </nav>
        <div className="header-actions">
          <LanguageSelect
            language={language}
            onChange={setLanguage}
            label={t.languageLabel}
          />
          <a className="button button-dark header-cta" href="/crafts">
            {t.exploreCollection}
          </a>
        </div>
        <button
          className="menu-toggle"
          type="button"
          aria-expanded={menuOpen}
          aria-controls="mobile-navigation"
          aria-label={menuOpen ? t.menuClose : t.menuOpen}
          onClick={() => setMenuOpen((isOpen) => !isOpen)}
        >
          <span />
          <span />
          <span />
        </button>
      </div>
      {menuOpen && (
        <nav
          className="mobile-nav"
          id="mobile-navigation"
          aria-label="Mobile navigation"
        >
          {navigation.map(([label, href, page]) => (
            <a
              key={href}
              href={href}
              className={currentPage === page ? "is-active" : undefined}
              aria-current={currentPage === page ? "page" : undefined}
              onClick={() => setMenuOpen(false)}
            >
              {label}
            </a>
          ))}
        </nav>
      )}
    </header>
  );
}

export function Hero({ t, image = heroImage }) {
  return (
    <section className="hero" id="home">
      <img className="hero-image" src={image} alt="Natural woven textiles" />
      <div className="hero-shade" />
      <div className="hero-content page-width">
        <p className="eyebrow eyebrow-light">
          {t.heroBadge}
        </p>
        <h1>
          {t.heroTitleStart} <em>{t.heroTitleAccent}</em>
          <br />
          {t.heroTitleEnd}
        </h1>
        <p className="hero-copy">{t.heroCopy}</p>
        <div className="hero-actions">
          <a className="button button-light" href="/crafts">
            {t.discoverCrafts}
          </a>
          <a className="button button-accent" href="/story">
            {t.ourStory}
          </a>
        </div>
        <div className="hero-stats">
          <div>
            <strong>1990</strong>
            <span>{t.established}</span>
          </div>
          <i />
          <div>
            <strong>{t.heroBadge}</strong>
            <span>{t.tradition}</span>
          </div>
        </div>
      </div>
      <span className="hero-note">{t.footerTagline}</span>
    </section>
  );
}

export function Introduction({ t }) {
  return (
    <section className="intro-section section-space">
      <div className="intro-copy">
        <p className="eyebrow">{t.moreThanCraft}</p>
        <h2>{t.introTitle}</h2>
        <p>{t.introCopy}</p>
      </div>
    </section>
  );
}

export function CategoryShowcase({
  onChooseCategory,
  t,
  items = categoryShowcases,
  images = {},
}) {
  return (
    <section className="showcase-section section-space">
      <div className="page-width">
        <div className="section-heading heading-split">
          <div>
            <p className="eyebrow">{t.exploreWorld}</p>
            <h2>{t.craftedEveryday}</h2>
          </div>
          <p>{t.exploreWorldCopy}</p>
        </div>
        <div className="showcase-grid">
          {items.map((item) => (
            <a
              className="showcase-card"
              href="/crafts"
              key={item.id}
              onClick={() => onChooseCategory(item.id)}
            >
              <img
                src={images.showcase?.[item.id] ?? item.image}
                alt={item.alt}
                loading="lazy"
              />
              <span className="showcase-shade" />
              <span className="showcase-copy">
                <small>{item.eyebrow}</small>
                <strong>{item.title}</strong>
                <span className="button button-light showcase-action">
                  {t.exploreCollectionLink}
                </span>
              </span>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Collection({
  activeCategory,
  onChooseCategory,
  searchTerm,
  onSearchChange,
  visibleCrafts,
  onEnquire,
  t,
}) {
  return (
    <section className="collection-section section-space" id="collection">
      <div className="page-width">
        <div className="section-heading heading-center">
          <p className="eyebrow">{t.ourCreations}</p>
          <h2>{t.collectionTitle}</h2>
          <p>{t.collectionCopy}</p>
        </div>
        <label className="search-field">
          <span className="sr-only">{t.searchLabel}</span>
          <svg
            aria-hidden="true"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
          >
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-4-4" />
          </svg>
          <input
            type="search"
            value={searchTerm}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder={t.searchPlaceholder}
          />
        </label>
        <div className="filter-list" aria-label="Filter crafts by category">
          {categories.map((category) => (
            <button
              className={
                activeCategory === category.id
                  ? "filter-button is-active"
                  : "filter-button"
              }
              key={category.id}
              type="button"
              aria-pressed={activeCategory === category.id}
              onClick={() => onChooseCategory(category.id)}
            >
              {category.label}
            </button>
          ))}
        </div>
        {visibleCrafts.length > 0 ? (
          <div className="product-grid">
            {visibleCrafts.map((craft) => (
              <article className="product-card" key={craft.id}>
                <div className="product-image">
                  <img src={craft.image} alt={craft.alt} loading="lazy" />
                  <span>{craft.badge}</span>
                </div>
                <div className="product-copy">
                  <p className="product-category">{craft.categoryLabel}</p>
                  <h3>{craft.name}</h3>
                  <p>{craft.description}</p>
                  <button
                    className="button button-dark product-action"
                    type="button"
                    onClick={() => onEnquire(craft.name)}
                  >
                    {t.enquireLink}
                  </button>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <p className="no-results" role="status">
            {t.noResults}
          </p>
        )}
        <p className="catalog-note">{t.inTheShop}</p>
      </div>
    </section>
  );
}

export function Story({ t, image = storyImage }) {
  return (
    <section className="story-section section-space" id="story">
      <div className="story-layout page-width">
        <div className="story-image-wrap">
          <img src={image} alt="Handwoven wool wall art made in Lesotho" loading="lazy" />
          <div className="story-year">
            <strong>1990</strong>
            <span>{t.established}</span>
          </div>
        </div>
        <div className="story-copy">
          <p className="eyebrow">{t.storyEyebrow}</p>
          <h2>{t.storyTitle}</h2>
          <p>{t.storyParagraphOne}</p>
          <p>{t.storyParagraphTwo}</p>
          <a className="button button-dark" href="/contact">
            {t.getToKnowUs}
          </a>
        </div>
      </div>
    </section>
  );
}

export function CraftProcess({ t, steps = craftSteps, images = {} }) {
  return (
    <section className="process-section section-space" id="craft">
      <div className="page-width">
        <div className="section-heading heading-center">
          <p className="eyebrow">{t.craftEyebrow}</p>
          <h2>{t.craftTitle}</h2>
          <p>{t.craftCopy}</p>
        </div>
        <div className="process-grid">
          {steps.map((step) => (
            <article className="process-card" key={step.number}>
              <div className="process-image">
                <img
                  src={images.process?.[step.number] ?? step.image}
                  alt={step.alt}
                  loading="lazy"
                />
              </div>
              <span className="process-label">
                {step.number} · {step.label}
              </span>
              <h3>{step.title}</h3>
              <p>{step.description}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export function CallToAction({ t, image = callToActionImage }) {
  return (
    <section className="cta-section">
      <img
        src={image}
        alt=""
        className="cta-texture"
        aria-hidden="true"
      />
      <div className="cta-copy">
        <p className="eyebrow eyebrow-light">{t.discoverHeritage}</p>
        <h2>{t.ctaTitle}</h2>
        <p>{t.ctaCopy}</p>
        <a className="button button-light" href="/contact">
          {t.contactSeithati}
        </a>
      </div>
    </section>
  );
}

export function Contact({
  onSubmit,
  onWhatsApp,
  t,
  contactDetails: details = contactDetails,
}) {
  return (
    <section className="contact-section section-space" id="contact">
      <div className="contact-layout page-width">
        <div className="contact-copy">
          <p className="eyebrow">{t.connect}</p>
          <h2>{t.contactTitle}</h2>
          <p>{t.contactCopy}</p>
          <div className="contact-details">
            <div className="contact-location contact-phone-list">
              <span className="contact-icon" aria-hidden="true">☎</span>
              <span>
                <strong>{t.callOrWhatsApp}</strong>
                <span>
                  <a href={`tel:${details.phone.replace(/\s+/g, "")}`}>
                    {details.phone}
                  </a>
                </span>
                {details.secondaryPhone && (
                  <span>
                    <a
                      href={`tel:${details.secondaryPhone.replace(/\s+/g, "")}`}
                    >
                      {details.secondaryPhone}
                    </a>
                  </span>
                )}
              </span>
            </div>
            <a href={`mailto:${details.email}`}>
              <span className="contact-icon" aria-hidden="true">✉</span>
              <span>
                <strong>{t.email}</strong>
                <span>{details.email}</span>
              </span>
            </a>
            <div className="contact-location">
              <span className="contact-icon" aria-hidden="true">⌖</span>
              <span>
                <strong>{t.location}</strong>
                <address className="workshop-address">
                  <span>{details.fullAddress}</span>
                  <ul>
                    <li>{t.workshopDistance}</li>
                    <li>{t.workshopDirection}</li>
                    <li>{t.workshopArea}</li>
                    <li>{t.workshopRoadside}</li>
                  </ul>
                </address>
              </span>
            </div>
          </div>
          <button
            className="button button-whatsapp"
            type="button"
            onClick={() =>
              onWhatsApp(
                "Hello Seithati Weavers, I would like to learn more about your handmade crafts.",
              )
            }
          >
            {t.messageUs}
          </button>
        </div>
        <form className="enquiry-form" onSubmit={onSubmit}>
          <h3>{t.formTitle}</h3>
          <label>
            {t.name}
            <input name="name" autoComplete="name" required />
          </label>
          <label>
            {t.emailField}
            <input
              name="email"
              type="email"
              autoComplete="email"
              placeholder="you@example.com"
              required
            />
          </label>
          <label>
            {t.interest}
            <select name="subject" defaultValue={t.subjectGeneral}>
              <option>{t.subjectGeneral}</option>
              <option>{t.subjectProduct}</option>
              <option>{t.subjectCustom}</option>
              <option>{t.subjectBusiness}</option>
            </select>
          </label>
          <label>
            {t.message}
            <textarea name="message" rows="4" required />
          </label>
          <button className="button button-dark form-submit" type="submit">
            {t.submit}
          </button>
          <p className="form-note">{t.formNote}</p>
        </form>
      </div>
    </section>
  );
}

export function Footer({
  onChooseCategory,
  t,
  contactDetails: details = contactDetails,
}) {
  return (
    <footer className="site-footer">
      <div className="footer-main page-width">
        <div className="footer-about">
          <a className="footer-brand" href="/">Seithati Weavers</a>
          <p>{t.footerTagline}</p>
          <a
            className="footer-social-link"
            href="https://www.facebook.com/profile.php?id=61596467557199"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Visit Seithati Weavers on Facebook"
          >
            <svg
              aria-hidden="true"
              viewBox="0 0 24 24"
              focusable="false"
            >
              <path d="M13.5 21v-8.2h2.8l.4-3.2h-3.2V7.5c0-.9.3-1.6 1.6-1.6h1.7V3.1c-.3 0-1.3-.1-2.5-.1-2.5 0-4.2 1.5-4.2 4.3v2.3H7.3v3.2h2.8V21h3.4Z" />
            </svg>
            <span>Facebook</span>
          </a>
        </div>
        <div>
          <h3>{t.footerExplore}</h3>
          <div className="footer-links">
            {[
              [t.navigation.home, "/"],
              [t.navigation.crafts, "/crafts"],
              [t.navigation.story, "/story"],
              [t.navigation.craft, "/process"],
              [t.navigation.contact, "/contact"],
              [t.navigation.personalizedCrafts, "/personalized-crafts"],
              [t.navigation.chat, "/customer-chat"],
            ].map(([label, href]) => (
              <a href={href} key={href}>{label}</a>
            ))}
          </div>
        </div>
        <div>
          <h3>{t.footerCollections}</h3>
          <div className="footer-links">
            {categoryShowcases.map(({ id, title }) => (
              <a
                href="/crafts"
                key={id}
                onClick={() => onChooseCategory(id)}
              >
                {title}
              </a>
            ))}
          </div>
        </div>
        <div>
          <h3>{t.footerGetInTouch}</h3>
          <div className="footer-links">
            {details.secondaryPhone && (
              <a href={`tel:${details.secondaryPhone.replace(/\s+/g, "")}`}>
                {details.secondaryPhone}
              </a>
            )}
            <a
              href={`https://wa.me/${details.whatsapp}`}
              target="_blank"
              rel="noreferrer"
            >
              WhatsApp: {details.phone}
            </a>
            <a href={`mailto:${details.email}`}>{details.email}</a>
            <a href="/contact">{details.fullAddress}</a>
          </div>
        </div>
      </div>
      <div className="footer-bottom page-width">
        <span>{t.footerRights.replace("{year}", new Date().getFullYear())}</span>
        <span>{t.footerTagline}</span>
      </div>
    </footer>
  );
}
