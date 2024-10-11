const onGrecaptchaLoad = function grecaptchaLoad() {
  window.grecaptcha.ready(() => {
    if (window.atsVisitorScore) return;

    const action = "load";

    window.grecaptcha
      // eslint-disable-next-line no-undef
      .execute(gon.recaptcha_v3_site_key, { action })
      .then((token) => {
        fetch("/recaptcha/verify", {
          method: "post",
          creadentials: "include",
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ token, recaptcha_action: action }),
        }).then((response) => {
          response.json().then((data) => {
            if (data.action === action) {
              window.atsVisitorScore = data.score;
              // Works when we calculate recaptcha_v3_score on the register page.
              const scoreField = document.getElementById("recaptcha_v3_score");
              if (scoreField) scoreField.value = data.score;
            }
          });
        });
      });
  });
};
window.onGrecaptchaLoad = onGrecaptchaLoad;
