export function PersonalizedCraftPage({ contactDetails, t }) {
  return (
    <section className="personalized-section section-space">
      <div className="personalized-layout page-width">
        <div className="personalized-intro">
          <p className="eyebrow">{t.customEyebrow}</p>
          <h1>{t.customTitle}</h1>
          <p>{t.customIntro}</p>

          <div className="custom-service-steps">
            <h2>{t.customHowTitle}</h2>
            <ol>
              <li><strong>{t.customStepOneTitle}</strong> {t.customStepOne}</li>
              <li><strong>{t.customStepTwoTitle}</strong> {t.customStepTwo}</li>
              <li><strong>{t.customStepThreeTitle}</strong> {t.customStepThree}</li>
              <li><strong>{t.customStepFourTitle}</strong> {t.customStepFour}</li>
            </ol>
          </div>
        </div>

        <div className="custom-contact-card personalized-contact-card">
          <h2>{t.customQuestionsTitle}</h2>
          <p>{t.customQuestionsCopy}</p>
          <a className="button button-dark talk-to-us-button" href="/customer-chat">
            {t.talkToUsNow}
          </a>
          <span>{t.chatAccountNotice}</span>
          <a href={`tel:${contactDetails.phone.replace(/\s+/g, "")}`}>
            {contactDetails.phone}
          </a>
          {contactDetails.secondaryPhone && (
            <a href={`tel:${contactDetails.secondaryPhone.replace(/\s+/g, "")}`}>
              {contactDetails.secondaryPhone}
            </a>
          )}
          <a href={`https://wa.me/${contactDetails.whatsapp}`} target="_blank" rel="noreferrer">
            WhatsApp
          </a>
          <a href={`mailto:${contactDetails.email}`}>{contactDetails.email}</a>
          <span>{contactDetails.location}</span>
        </div>
      </div>
    </section>
  );
}
