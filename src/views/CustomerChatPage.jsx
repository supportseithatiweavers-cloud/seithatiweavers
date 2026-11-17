import { useEffect, useRef, useState } from "react";
import { auth } from "../firebase.js";

function isPrivateChatImage(url) {
  try {
    return new URL(url).pathname.startsWith("/chat-media/");
  } catch {
    return false;
  }
}

export function ChatImage({ url, alt, label }) {
  const [imageSource, setImageSource] = useState("");
  const [failed, setFailed] = useState(false);
  const isPrivate = isPrivateChatImage(url);

  useEffect(() => {
    if (!isPrivate) {
      setImageSource("");
      setFailed(false);
      return undefined;
    }

    let cancelled = false;
    let objectUrl = "";
    setImageSource("");
    setFailed(false);

    const loadImage = async () => {
      try {
        const token = await auth.currentUser?.getIdToken();
        if (!token) throw new Error("Sign in again to view this image.");

        const response = await fetch(url, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!response.ok) throw new Error(`Image request failed (${response.status}).`);

        objectUrl = URL.createObjectURL(await response.blob());
        if (cancelled) {
          URL.revokeObjectURL(objectUrl);
          return;
        }
        setImageSource(objectUrl);
      } catch (error) {
        console.error("Could not load a customer chat image.", error);
        if (!cancelled) setFailed(true);
      }
    };

    loadImage();
    return () => {
      cancelled = true;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [isPrivate, url]);

  const source = isPrivate ? imageSource : url;
  return (
    <>
      {source && (
        <a
          className="chat-image-link"
          href={source}
          target="_blank"
          rel="noreferrer"
        >
          <img src={source} alt={alt} />
          <span>{label}</span>
        </a>
      )}
      {!source && (
        <span className="chat-image-status">
          {failed ? "Unable to load image." : "Loading image…"}
        </span>
      )}
    </>
  );
}

export function formatChatTimestamp(createdAt, language = "en") {
  const date = createdAt?.toDate?.();
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) return "";
  const locale = language === "st" ? "st-LS" : "en-LS";
  return new Intl.DateTimeFormat(locale, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

function ChatMessage({ message, language, patternLabel }) {
  const isCustomer = message.sender === "customer";
  const timestamp = formatChatTimestamp(message.createdAt, language);
  return (
    <div className={`chat-message-row ${isCustomer ? "customer" : "staff"}`}>
      <div className="chat-message-content">
        <span className="chat-bubble">
          {message.text && <span>{message.text}</span>}
          {message.imageUrl && (
            <ChatImage
              url={message.imageUrl}
              alt={message.imageName || patternLabel}
              label={message.imageName || patternLabel}
            />
          )}
        </span>
        {timestamp && (
          <time className="chat-message-time" dateTime={message.createdAt.toDate().toISOString()}>
            {timestamp}
          </time>
        )}
      </div>
    </div>
  );
}

export function CustomerChatPage({ onOpenChat, t }) {
  return (
    <section className="personalized-section section-space">
      <div className="personalized-layout page-width">
        <div className="personalized-intro">
          <p className="eyebrow">{t.chatEyebrow}</p>
          <h1>{t.chatTitle}</h1>
          <p>{t.chatIntro}</p>
        </div>
        <div className="chat-launch-card">
          <span className="chat-launch-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24">
              <path d="M20 11.5a7.5 7.5 0 0 1-7.5 7.5H6l-3 2v-6a7.5 7.5 0 1 1 17-3.5Z" />
              <path d="M8 10h8M8 14h5" />
            </svg>
          </span>
          <h2>{t.chatLive}</h2>
          <button
            type="button"
            className="button button-dark google-sign-in-button"
            onClick={onOpenChat}
          >
            {t.chatOpen}
          </button>
        </div>
      </div>
    </section>
  );
}

export function ChatFloatingWidget({
  embedded = false,
  isOpen,
  onOpenChange,
  onUnreadChange,
  error,
  isSignedIn,
  adminOnline,
  adminName = "Seithati Weavers",
  adminProfileImageUrl = "",
  onGoogleSignIn,
  onFormSubmit,
  messages,
  sending,
  signingIn,
  user,
  language,
  t,
}) {
  const [unread, setUnread] = useState(0);
  const seenMessages = useRef(new Set());
  const threadRef = useRef(null);

  useEffect(() => {
    seenMessages.current.clear();
    setUnread(0);
  }, [user?.uid]);

  useEffect(() => {
    if (isOpen) {
      setUnread(0);
      messages.forEach((message) => seenMessages.current.add(message.id));
      return;
    }

    const unseenStaffMessages = messages.filter(
      (message) =>
        message.sender === "staff" && !seenMessages.current.has(message.id),
    );
    if (seenMessages.current.size > 0 && unseenStaffMessages.length > 0) {
      setUnread((count) => count + unseenStaffMessages.length);
    }
    messages.forEach((message) => seenMessages.current.add(message.id));
  }, [isOpen, messages]);

  useEffect(() => {
    onUnreadChange?.(unread);
  }, [onUnreadChange, unread]);

  useEffect(() => {
    if (isOpen && threadRef.current) {
      threadRef.current.scrollTop = threadRef.current.scrollHeight;
    }
  }, [isOpen, messages]);

  return (
    <aside
      className={`floating-chat-widget ${isOpen ? "is-open" : ""} ${embedded ? "is-embedded" : ""}`}
    >
      {isOpen && (
        <section
          className="floating-chat-window"
          role="dialog"
          aria-label={t.chatTitle}
        >
          <header className="floating-chat-header">
            <div className="floating-chat-brand">
              <span className="floating-chat-avatar" aria-hidden="true">
                {adminProfileImageUrl ? (
                  <img src={adminProfileImageUrl} alt="" />
                ) : (
                  adminName.slice(0, 1).toUpperCase()
                )}
              </span>
              <span>
                <strong>{adminName}</strong>
                <span className={`chat-presence ${adminOnline ? "is-online" : ""}`}>
                  <span aria-hidden="true" />
                  {adminOnline ? t.chatAdminOnline : t.chatAdminOffline}
                </span>
              </span>
            </div>
            <div className="floating-chat-actions">
              <span
                className="chat-notification-icon"
                role="img"
                aria-label={unread ? `${unread} ${t.chatNotifications}` : t.chatNotifications}
                title={unread ? `${unread} ${t.chatNotifications}` : t.chatNotifications}
              >
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />
                </svg>
                {unread > 0 && <span>{unread > 9 ? "9+" : unread}</span>}
              </span>
              <button
                type="button"
                className="floating-chat-close"
                onClick={() => onOpenChange(false)}
                aria-label={t.chatClose}
              >
                ×
              </button>
            </div>
          </header>

          {isSignedIn ? (
            <>
              <div className="floating-chat-thread chat-thread" ref={threadRef} aria-live="polite">
                {messages.length === 0 ? (
                  <p className="chat-empty">{t.chatEmptyState}</p>
                ) : (
                  messages.map((message) => (
                    <ChatMessage
                      key={message.id}
                      message={message}
                      language={language}
                      patternLabel={t.chatPatternImage}
                    />
                  ))
                )}
              </div>
              <form className="floating-chat-composer" onSubmit={onFormSubmit}>
                <input
                  name="message"
                  placeholder={t.chatMessagePlaceholder}
                  aria-label={t.chatMessagePlaceholder}
                />
                <label className="floating-chat-attach" title={t.chatAttachPattern}>
                  <input name="image" type="file" accept="image/jpeg,image/png,image/webp" />
                  <span aria-hidden="true">＋</span>
                  <span className="sr-only">{t.chatAttachPattern}</span>
                </label>
                <button type="submit" disabled={sending} aria-label={sending ? t.chatSending : t.chatSend}>
                  {sending ? "…" : "➤"}
                </button>
              </form>
              <p className="floating-chat-note">{t.chatImageLimit}</p>
            </>
          ) : (
            <div className="floating-chat-signin">
              <p>{t.chatLoginCopy}</p>
              <button
                className="button button-dark google-sign-in-button"
                type="button"
                onClick={onGoogleSignIn}
                disabled={signingIn}
              >
                {signingIn ? t.chatGoogleSigningIn : t.chatGoogleSignIn}
              </button>
            </div>
          )}
          {error && <p className="request-feedback request-error floating-chat-error">{error}</p>}
        </section>
      )}
      {!embedded && (
        <button
          className="floating-chat-launcher"
          type="button"
          aria-label={isOpen ? t.chatClose : t.chatOpen}
          aria-expanded={isOpen}
          onClick={() => {
            onOpenChange(!isOpen);
            setUnread(0);
          }}
        >
          {isOpen ? (
            <span aria-hidden="true">×</span>
          ) : (
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M20 11.5a7.5 7.5 0 0 1-7.5 7.5H6l-3 2v-6a7.5 7.5 0 1 1 17-3.5Z" />
              <path d="M8 10h8M8 14h5" />
            </svg>
          )}
          {unread > 0 && !isOpen && (
            <span className="floating-chat-unread">{unread > 9 ? "9+" : unread}</span>
          )}
        </button>
      )}
    </aside>
  );
}
