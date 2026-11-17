import { useEffect, useState } from "react";
import { useCraftCatalog } from "./controllers/useCraftCatalog.js";
import { useContact } from "./controllers/useContact.js";
import { useSiteContent } from "./controllers/useSiteContent.js";
import {
  useAdminPresence,
  useCustomerAuth,
  useCustomerChat,
} from "./controllers/useCustomerChat.js";
import {
  ChatFloatingWidget,
  CustomerChatPage,
} from "./views/CustomerChatPage.jsx";
import { PersonalizedCraftPage } from "./views/PersonalizedCraftPage.jsx";
import {
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
        "You can call {phoneNumbers}, message us on WhatsApp, or send an enquiry via the website form.",
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
        "U ka letsetsa {phoneNumbers}, u re romelle molaetsa ho WhatsApp, kapa u romelle potso ka foromo ea webosaete.",
    },
  ],
};

function getPageFromPath(pathname) {
  const page = pathname.replace(/^\/+|\/+$/g, "");

  if (page === "crafts" || page === "collection") return "crafts";
  if (page === "story") return "story";
  if (page === "craft" || page === "process") return "process";
  if (page === "contact") return "contact";
  if (page === "personalized-crafts") return "personalized-crafts";
  if (page === "customer-chat") return "customer-chat";
  return "home";
}

function getInitialPage() {
  const legacyRoutes = {
    "#home": "/",
    "#crafts": "/crafts",
    "#collection": "/crafts",
    "#story": "/story",
    "#craft": "/process",
    "#process": "/process",
    "#contact": "/contact",
    "#chat": "/customer-chat",
  };
  const route = legacyRoutes[window.location.hash];

  if (route) {
    window.history.replaceState({}, "", route);
    return getPageFromPath(route);
  }

  return getPageFromPath(window.location.pathname);
}

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

  if (type === "chat") {
    return (
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M20 11.5a7.5 7.5 0 0 1-7.5 7.5H6l-3 2v-6a7.5 7.5 0 1 1 17-3.5Z"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="1.8"
        />
        <path
          d="M8 10h8M8 14h5"
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeWidth="1.8"
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

function FloatingHelp({
  language,
  setLanguage,
  contactDetails,
  chatOpenRequest,
  chatError,
  isSignedIn,
  adminOnline,
  adminName,
  adminProfileImageUrl,
  onGoogleSignIn,
  onFormSubmit,
  messages,
  sending,
  signingIn,
  user,
  t,
}) {
  const [open, setOpen] = useState(false);
  const [faqOpen, setFaqOpen] = useState(false);
  const [liveChatOpen, setLiveChatOpen] = useState(false);
  const [unreadChatMessages, setUnreadChatMessages] = useState(0);
  const [conversation, setConversation] = useState([]);
  const phoneNumbers = [
    ...new Map(
      [contactDetails.phone, contactDetails.secondaryPhone]
        .filter(Boolean)
        .map((phone) => [phone.replace(/\D/g, ""), phone.trim()]),
    ).values(),
  ];
  const faqEntries = (quickFaq[language] ?? quickFaq.en).map((item) => ({
    ...item,
    answer: item.answer.replace(
      "{phoneNumbers}",
      phoneNumbers.join(language === "st" ? " kapa " : " or "),
    ),
  }));
  const whatsappUrl = new URL(`https://wa.me/${contactDetails.whatsapp}`);
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

  const toggleHelp = () => {
    if (open) {
      setOpen(false);
      setFaqOpen(false);
      setLiveChatOpen(false);
      return;
    }
    setOpen(true);
  };

  useEffect(() => {
    setConversation([]);
  }, [language]);

  useEffect(() => {
    if (chatOpenRequest > 0) {
      setOpen(true);
      setFaqOpen(false);
      setLiveChatOpen(true);
    }
  }, [chatOpenRequest]);

  return (
    <div className="help-widget">
      <div className="help-popover" hidden={!open}>
        <ChatFloatingWidget
          embedded
          isOpen={liveChatOpen}
          onOpenChange={setLiveChatOpen}
          onUnreadChange={setUnreadChatMessages}
          error={chatError}
          isSignedIn={isSignedIn}
          adminOnline={adminOnline}
          adminName={adminName}
          adminProfileImageUrl={adminProfileImageUrl}
          onGoogleSignIn={onGoogleSignIn}
          onFormSubmit={onFormSubmit}
          messages={messages}
          sending={sending}
          signingIn={signingIn}
          user={user}
          language={language}
          t={t}
        />
        {!liveChatOpen && (
          <>
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
              {phoneNumbers.map((phone) => (
                <a
                  className="help-service"
                  href={`tel:${phone.replace(/\s+/g, "")}`}
                  key={phone}
                >
                  <span className="help-service-icon">
                    <ServiceIcon type="phone" />
                  </span>
                  {language === "en" ? `Call ${phone}` : `Letsetsa ${phone}`}
                </a>
              ))}
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
                onClick={() => setLiveChatOpen(true)}
              >
                <span className="help-service-icon help-ai-icon">
                  <ServiceIcon type="chat" />
                </span>
                <span className="help-service-label">
                  {language === "en" ? "Live chat" : "Puisano e phelang"}
                </span>
                {unreadChatMessages > 0 && (
                  <span className="help-chat-unread">
                    {unreadChatMessages > 9 ? "9+" : unreadChatMessages}
                  </span>
                )}
              </button>
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
          </>
        )}
      </div>
      <button
        className="help-fab"
        type="button"
        onClick={toggleHelp}
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
  const [currentPage, setCurrentPage] = useState(getInitialPage);
  const [chatAuthError, setChatAuthError] = useState("");
  const [chatOpenRequest, setChatOpenRequest] = useState(0);
  const content = useSiteContent();
  const catalog = useCraftCatalog(content.crafts);
  const contact = useContact(content.contact);
  const authState = useCustomerAuth();
  const customerChat = useCustomerChat(authState.user);
  const adminPresence = useAdminPresence();
  const t = content.translations[language];

  const handleGoogleSignIn = async () => {
    setChatAuthError("");
    const result = await authState.signInWithGoogle();
    if (!result.success) setChatAuthError(result.message);
  };
  const handleChatSubmit = (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const formData = new FormData(form);
    const message = String(formData.get("message") ?? "").trim();
    const image = formData.get("image");
    customerChat
      .sendMessage(message, image instanceof File && image.size ? image : null)
      .then((sent) => {
        if (sent) form.reset();
      });
  };

  useEffect(() => {
    const handleNavigation = () => {
      setCurrentPage(getPageFromPath(window.location.pathname));
      window.scrollTo({ top: 0, behavior: "smooth" });
    };

    const handleInternalLink = (event) => {
      if (
        event.defaultPrevented ||
        event.button !== 0 ||
        event.metaKey ||
        event.ctrlKey ||
        event.shiftKey ||
        event.altKey
      ) {
        return;
      }

      const link = event.target.closest("a[href]");
      if (!link || link.target || link.hasAttribute("download")) {
        return;
      }

      const destination = new URL(link.href, window.location.href);
      const appRoutes = [
        "/",
        "/home",
        "/crafts",
        "/collection",
        "/story",
        "/craft",
        "/process",
        "/contact",
        "/personalized-crafts",
        "/customer-chat",
      ];
      if (
        destination.origin !== window.location.origin ||
        !appRoutes.includes(destination.pathname)
      ) {
        return;
      }

      event.preventDefault();
      if (destination.pathname !== window.location.pathname) {
        window.history.pushState({}, "", destination.pathname);
        handleNavigation();
      }
    };

    window.addEventListener("popstate", handleNavigation);
    document.addEventListener("click", handleInternalLink);
    return () => {
      window.removeEventListener("popstate", handleNavigation);
      document.removeEventListener("click", handleInternalLink);
    };
  }, []);

  return (
    <>
      <Header
        language={language}
        setLanguage={setLanguage}
        t={t}
        currentPage={currentPage}
      />
      <main className="page-view" key={currentPage}>
        {currentPage === "customer-chat" && (
          authState.loading ? (
            <section className="section-space page-width" aria-live="polite">
              <p>{t.chatCheckingAccount}</p>
            </section>
          ) : <CustomerChatPage
            onOpenChat={() => setChatOpenRequest((request) => request + 1)}
            t={t}
          />
        )}
        {currentPage === "home" && (
          <>
            <Hero t={t} image={content.images.hero} />
            <Introduction t={t} />
            <CategoryShowcase
              t={t}
              items={content.categoryShowcases}
              images={content.images}
              onChooseCategory={catalog.setActiveCategory}
            />
          </>
        )}
        {currentPage === "crafts" && (
          <Collection
            activeCategory={catalog.activeCategory}
            onChooseCategory={catalog.setActiveCategory}
            searchTerm={catalog.searchTerm}
            onSearchChange={catalog.setSearchTerm}
            visibleCrafts={catalog.visibleCrafts}
            onEnquire={contact.enquireAboutCraft}
            t={t}
          />
        )}
        {currentPage === "story" && (
          <Story t={t} image={content.images.story} />
        )}
        {currentPage === "process" && (
          <>
            <CraftProcess
              t={t}
              steps={content.craftSteps}
              images={content.images}
            />
            <CallToAction t={t} image={content.images.cta} />
          </>
        )}
        {currentPage === "contact" && (
          <Contact
            onSubmit={contact.sendEnquiry}
            onWhatsApp={contact.openWhatsApp}
            contactDetails={content.contact}
            t={t}
            language={language}
          />
        )}
        {currentPage === "personalized-crafts" && (
          <PersonalizedCraftPage
            contactDetails={content.contact}
            t={t}
          />
        )}
      </main>
      <Footer
        onChooseCategory={catalog.setActiveCategory}
        contactDetails={content.contact}
        t={t}
      />
      <FloatingHelp
        language={language}
        setLanguage={setLanguage}
        contactDetails={content.contact}
        chatOpenRequest={chatOpenRequest}
        chatError={customerChat.chatError || authState.error || chatAuthError}
        isSignedIn={Boolean(authState.user)}
        adminOnline={adminPresence.online}
        adminName={adminPresence.profileName}
        adminProfileImageUrl={adminPresence.profileImageUrl}
        onGoogleSignIn={handleGoogleSignIn}
        onFormSubmit={handleChatSubmit}
        messages={customerChat.messages}
        sending={customerChat.chatStatus === "sending"}
        signingIn={authState.authenticating}
        user={authState.user}
        t={t}
      />
    </>
  );
}
