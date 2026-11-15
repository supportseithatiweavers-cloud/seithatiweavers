import { useEffect, useState } from "react";
import { useCraftCatalog } from "./controllers/useCraftCatalog.js";
import { useContact } from "./controllers/useContact.js";
import { useSiteContent } from "./controllers/useSiteContent.js";
import {
  Announcement,
  CallToAction,
  CategoryShowcase,
  Collection,
  Contact,
  CraftProcess,
  Footer,
  Header,
  Hero,
  Introduction,
  LanguageSelect,
  Story,
} from "./views/SiteSections.jsx";

const quickFaq = {
  en: [
    {
      question: "Where are you located?",
      answer:
        "We are based in Maseru, Lesotho, and welcome enquiries from visitors and buyers looking for handcrafted woven items.",
    },
    {
      question: "How do I place an order?",
      answer:
        "Send us a message through the enquiry form, WhatsApp, or phone call, and we will guide you on available products and delivery details.",
    },
    {
      question: "Do you offer custom designs?",
      answer:
        "Yes. We create custom and made-to-order pieces based on customer ideas, colours, and style preferences.",
    },
    {
      question: "What products do you make?",
      answer:
        "We make woven bags, rugs, wall hangings, cushions, blankets, and other handcrafted textile pieces inspired by Basotho culture.",
    },
    {
      question: "How can I contact you?",
      answer:
        "You can call +2663315077, message us on WhatsApp, or send an enquiry via the website form.",
    },
  ],
  st: [
    {
      question: "U fumaneha kae?",
      answer:
        "Re base Maseru, Lesotho, 'me re amohela lipotso ho baeti le bareki ba batlang lihlahisoa tse loiloeng ka letsoho.",
    },
    {
      question: "Ke etsa joang ho odara?",
      answer:
        "Romella molaetsa ka foromo ea potso, WhatsApp, kapa mohala, 'me re tla u tataisa ka lihlahisoa tse fumanehang le lintlha tsa ho romelloa.",
    },
    {
      question: "Na le fana ka meralo e ikhethang?",
      answer:
        "Ee. Re etsa lihlahisoa tse ikhethileng le tse etselitsoeng taelo ho latela mehopolo, mebala le litakatso tsa moreki.",
    },
    {
      question: "Na le etsa lihlahisoa life?",
      answer:
        "Re etsa mekotla e loiloeng, marako, li-cushion, li-blanket, le lihlahisoa tse ling tse entsoeng ka letsoho tsa masela tse bululetsoang ke setso sa Basotho.",
    },
    {
      question: "Nka ikopanya joang le lona?",
      answer:
        "U ka letsetsa +2663315077, u re romelle molaetsa ho WhatsApp, kapa u romelle potso ka foromo ea webosaete.",
    },
  ],
};

function ServiceIcon({ type }) {
  if (type === "phone") {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M5 3.5h3l1.5 4-2 1.7a15 15 0 0 0 7.3 7.3l1.7-2 4 1.5v3c0 1.1-.9 2-2 2C10 21 3 14 3 5.5c0-1.1.9-2 2-2Z"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="1.8"
        />
      </svg>
    );
  }

  if (type === "whatsapp") {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M20.2 11.7a8.2 8.2 0 0 1-12.1 7.2L3 20l1.2-4.9a8.2 8.2 0 1 1 16-3.4Z"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="1.7"
        />
        <path
          d="M8.2 7.8c.3-.5.6-.5 1-.5h.4c.2 0 .4.1.5.4l.7 1.7c.1.2 0 .4-.1.6l-.5.6c-.2.2-.2.4-.1.6.5 1 1.3 1.8 2.3 2.3.2.1.4.1.6-.1l.7-.8c.2-.2.4-.2.6-.1l1.6.8c.3.1.4.3.4.5 0 .4-.2 1-.6 1.3-.4.4-1 .6-1.5.5-1.3-.1-2.8-.9-4-2-1.3-1.2-2-2.5-2.3-3.6-.2-.9.1-1.8.3-2.2Z"
          fill="currentColor"
        />
      </svg>
    );
  }

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path
        d="m12 2.8 2.3 6.9 6.9 2.3-6.9 2.3-2.3 6.9-2.3-6.9-6.9-2.3 6.9-2.3L12 2.8Z"
        fill="currentColor"
        stroke="currentColor"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function FloatingHelp({ language, setLanguage }) {
  const [open, setOpen] = useState(false);
  const [faqOpen, setFaqOpen] = useState(false);
  const [conversation, setConversation] = useState([]);
  const faqEntries = quickFaq[language] ?? quickFaq.en;
  const whatsappUrl = new URL("https://wa.me/2663315077");
  whatsappUrl.searchParams.set(
    "text",
    "Hello Seithati Weavers, I would like to learn more about your handmade crafts.",
  );

  const askQuestion = (item) => {
    setConversation((current) => [
      ...current,
      { role: "user", text: item.question },
      { role: "assistant", text: item.answer },
    ]);
  };

  useEffect(() => {
    setConversation([]);
  }, [language]);

  return (
    <div className="help-widget">
      {open && (
        <div className="help-popover">
          {faqOpen && (
            <section className="help-panel help-chat-panel" aria-label="Frequently asked questions">
              <div className="help-ai-header">
                <div>
                  <p className="help-panel-eyebrow">
                    {language === "en" ? "Ask AI" : "Botsa mothusi"}
                  </p>
                  <h3>
                    {language === "en"
                      ? "Seithati help"
                      : "Thuso ea Seithati"}
                  </h3>
                  <p className="faq-status">
                    <span />
                    {language === "en" ? "Here to help" : "Re teng ho thusa"}
                  </p>
                </div>
                <button
                  type="button"
                  className="close-ai"
                  onClick={() => setFaqOpen(false)}
                  aria-label={language === "en" ? "Close FAQ" : "Koala lipotso"}
                >
                  ×
                </button>
              </div>
              <div className="faq-language-select-wrap">
                <span>{language === "en" ? "Choose language" : "Khetha puo"}</span>
                <LanguageSelect
                  language={language}
                  onChange={setLanguage}
                  label={language === "en" ? "FAQ language" : "Puo ea lipotso"}
                />
              </div>
              <div className="faq-conversation" role="log" aria-live="polite">
                <div className="chat-message chat-message-assistant">
                  <span className="chat-avatar">
                    <ServiceIcon type="ai" />
                  </span>
                  <p className="chat-bubble">
                    {language === "en"
                      ? "Hello! Choose a question below and I’ll help you find an answer."
                      : "Lumela! Khetha potso e ka tlase, ke u thuse ka karabo."}
                  </p>
                </div>
                {conversation.map((message, index) => (
                  <div
                    className={`chat-message chat-message-${message.role}`}
                    key={`${message.role}-${index}`}
                  >
                    {message.role === "assistant" && (
                      <span className="chat-avatar">
                        <ServiceIcon type="ai" />
                      </span>
                    )}
                    <p className="chat-bubble">{message.text}</p>
                  </div>
                ))}
              </div>
              <div className="faq-suggestions">
                <span>
                  {language === "en" ? "Suggested questions" : "Lipotso tse khothalelitsoeng"}
                </span>
                {faqEntries.map((item) => (
                  <button
                    type="button"
                    key={item.question}
                    className="faq-suggestion"
                    onClick={() => askQuestion(item)}
                  >
                    {item.question}
                  </button>
                ))}
              </div>
            </section>
          )}
          <nav className="help-service-list" aria-label="Quick help">
            <a className="help-service" href="tel:+2663315077">
              <span className="help-service-icon">
                <ServiceIcon type="phone" />
              </span>
              {language === "en" ? "Call us" : "Re letsetse"}
            </a>
            <a
              className="help-service"
              href={whatsappUrl.toString()}
              target="_blank"
              rel="noreferrer"
            >
              <span className="help-service-icon help-whatsapp-icon">
                <ServiceIcon type="whatsapp" />
              </span>
              WhatsApp
            </a>
            <button
              type="button"
              className="help-service"
              onClick={() => {
                setFaqOpen((current) => !current);
              }}
            >
              <span className="help-service-icon help-ai-icon">
                <ServiceIcon type="ai" />
              </span>
              {language === "en" ? "Ask AI / FAQ" : "Botsa lipotso"}
            </button>
          </nav>
        </div>
      )}
      <button
        className="help-fab"
        type="button"
        onClick={() => setOpen((current) => !current)}
        aria-label={
          open
            ? language === "en"
              ? "Close help menu"
              : "Koala thuso"
            : language === "en"
              ? "Open help and FAQ"
              : "Bula thuso le lipotso"
        }
        aria-expanded={open}
      >
        <span aria-hidden="true">{open ? "×" : "✦"}</span>
        <span className="help-fab-label">
          {language === "en" ? "Need help?" : "U hloka thuso?"}
        </span>
      </button>
    </div>
  );
}

export default function App() {
  const [language, setLanguage] = useState("en");
  const content = useSiteContent();
  const catalog = useCraftCatalog(content.crafts);
  const contact = useContact(content.contact);
  const t = content.translations[language];

  return (
    <>
      <Announcement text={t.announcement} />
      <Header language={language} setLanguage={setLanguage} t={t} />
      <main>
        <Hero t={t} image={content.images.hero} />
        <Introduction t={t} />
        <CategoryShowcase
          t={t}
          items={content.categoryShowcases}
          images={content.images}
          onChooseCategory={catalog.setActiveCategory}
        />
        <Collection
          activeCategory={catalog.activeCategory}
          onChooseCategory={catalog.setActiveCategory}
          searchTerm={catalog.searchTerm}
          onSearchChange={catalog.setSearchTerm}
          visibleCrafts={catalog.visibleCrafts}
          onEnquire={contact.enquireAboutCraft}
          t={t}
        />
        <Story t={t} image={content.images.story} />
        <CraftProcess
          t={t}
          steps={content.craftSteps}
          images={content.images}
        />
        <CallToAction t={t} image={content.images.cta} />
        <Contact
          onSubmit={contact.sendEnquiry}
          onWhatsApp={contact.openWhatsApp}
          contactDetails={content.contact}
          t={t}
          language={language}
        />
      </main>
      <Footer
        onChooseCategory={catalog.setActiveCategory}
        contactDetails={content.contact}
        t={t}
      />
      <FloatingHelp language={language} setLanguage={setLanguage} />
    </>
  );
}
