<#--
  GoTravelNha login frame. Based on keycloak.v2/login/template.ftl (Keycloak 26.8.1): the <head> scripts,
  the nested sections and the PatternFly form classes are kept, so every built-in page (login, register,
  reset/update password, verify email, OTP, errors, ...) still works. The page chrome mirrors the web app's
  components/site/AuthShell.vue: form on the right, travel photo panel on the left (desktop only).
  When upgrading Keycloak, diff this file against the new keycloak.v2 template.
-->
<#import "field.ftl" as field>
<#import "footer.ftl" as loginFooter>
<#import "theme-resources.ftl" as themeResourceTags>

<#-- Per-page copy: "<base>.<pageId>" if the theme defines it, otherwise "<base>.default". -->
<#function gtnMsg base>
  <#local key = base + "." + pageId>
  <#local value = msg(key)>
  <#if value != key><#return value></#if>
  <#local fallback = base + ".default">
  <#local value = msg(fallback)>
  <#return (value != fallback)?then(value, "")>
</#function>

<#function gtnImage>
  <#switch pageId>
    <#case "register">
    <#case "login-update-profile">
    <#case "idp-review-user-profile">
      <#return "bg-register.jpg">
    <#case "login-reset-password">
    <#case "login-update-password">
    <#case "login-verify-email">
    <#case "update-email">
      <#return "bg-reset.jpg">
    <#default>
      <#return "bg-login.jpg">
  </#switch>
</#function>

<#macro logoMark size=30>
  <svg width="${size}" height="${size}" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false" class="gtn-logo-mark">
    <rect width="48" height="48" rx="13" fill="#0066E4"/>
    <path d="M24 39.5c-7-7.4-10.5-12.7-10.5-17.3a10.5 10.5 0 0 1 21 0c0 4.6-3.5 9.9-10.5 17.3Z" fill="#FFFFFF"/>
    <path d="M18.8 23 24 18.4l5.2 4.6v5.5H18.8Z" fill="#0066E4"/>
    <circle cx="35.5" cy="12.5" r="3.2" fill="#FBBF24"/>
  </svg>
</#macro>

<#macro username>
  <#assign label>
    <#if !realm.loginWithEmailAllowed>${msg("username")}<#elseif !realm.registrationEmailAsUsername>${msg("usernameOrEmail")}<#else>${msg("email")}</#if>
  </#assign>
  <@field.group name="username" label=label>
    <div class="${properties.kcInputGroup}">
      <div class="${properties.kcInputGroupItemClass} ${properties.kcFill}">
        <span class="${properties.kcInputClass} ${properties.kcFormReadOnlyClass}">
          <input id="kc-attempted-username" value="${auth.attemptedUsername}" readonly>
        </span>
      </div>
      <div class="${properties.kcInputGroupItemClass}">
        <button id="reset-login" class="${properties.kcFormPasswordVisibilityButtonClass} kc-login-tooltip" type="button"
              aria-label="${msg('restartLoginTooltip')}" onclick="location.href='${url.loginRestartFlowUrl}'">
            <i class="fa-sync-alt fas" aria-hidden="true"></i>
            <span class="kc-tooltip-text">${msg("restartLoginTooltip")}</span>
        </button>
      </div>
    </div>
  </@field.group>
</#macro>

<#macro registrationLayout bodyClass="" displayInfo=false displayMessage=true displayRequiredFields=false>
<#assign siteUrl = properties.gtnSiteUrl!"https://www.gotravelnha.com">
<#assign backUrl = (client?? && client.baseUrl?has_content)?then(client.baseUrl, "")>
<!DOCTYPE html>
<html class="${properties.kcHtmlClass!}" lang="${lang}"<#if realm.internationalizationEnabled> dir="${(locale.rtl)?then('rtl','ltr')}"</#if>>

<head>
    <meta charset="utf-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="color-scheme" content="light${darkMode?then(' dark', '')}">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="theme-color" content="#0066E4">

    <#if properties.meta?has_content>
        <#list properties.meta?split(' ') as meta>
            <meta name="${meta?split('==')[0]}" content="${meta?split('==')[1]}"/>
        </#list>
    </#if>
    <title>${title!} · GoTravelNha</title>
    <link rel="icon" type="image/svg+xml" href="${url.resourcesPath}/img/favicon.svg" />
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap">
    <#if themeResources?? && themeResources.stylesCommon?has_content>
        <@themeResourceTags.renderStyles themeResources.stylesCommon url.resourcesCommonPath />
    <#elseif properties.stylesCommon?has_content>
        <#list properties.stylesCommon?split(' ') as style>
            <link href="${url.resourcesCommonPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <#if themeResources?? && themeResources.styles?has_content>
        <@themeResourceTags.renderStyles themeResources.styles url.resourcesPath />
    <#elseif properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>
    <script type="importmap">
        {
            "imports": {
                "rfc4648": "${url.resourcesCommonPath}/vendor/rfc4648/rfc4648.js"
            }
        }
    </script>
    <#if darkMode>
      <script type="module" async blocking="render">
          <#outputformat "JavaScript">
          const DARK_MODE_CLASS = ${properties.kcDarkModeClass?c};
          const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

          updateDarkMode(mediaQuery.matches);
          mediaQuery.addEventListener("change", (event) => updateDarkMode(event.matches));

          function updateDarkMode(isEnabled) {
            const { classList } = document.documentElement;

            if (isEnabled) {
              classList.add(DARK_MODE_CLASS);
            } else {
              classList.remove(DARK_MODE_CLASS);
            }
          }
          </#outputformat>
      </script>
    </#if>
    <#if themeResources?? && themeResources.scripts?has_content>
        <@themeResourceTags.renderScripts themeResources.scripts url.resourcesPath "text/javascript" />
    <#elseif properties.scripts?has_content>
        <#list properties.scripts?split(' ') as script>
            <script src="${url.resourcesPath}/${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
    <script type="module" src="${url.resourcesPath}/js/passwordVisibility.js"></script>
    <script type="module">
        <#outputformat "JavaScript">
        import { startSessionPolling } from ${(url.resourcesPath + "/js/authChecker.js")?c};

        startSessionPolling(
            ${url.ssoLoginInOtherTabsUrl?c}
        );
        </#outputformat>
    </script>
    <script type="module">
        document.addEventListener("click", (event) => {
            const link = event.target.closest("a[data-once-link]");

            if (!link) {
                return;
            }

            if (link.getAttribute("aria-disabled") === "true") {
                event.preventDefault();
                return;
            }

            const { disabledClass } = link.dataset;

            if (disabledClass) {
                link.classList.add(...disabledClass.trim().split(/\s+/));
            }

            link.setAttribute("role", "link");
            link.setAttribute("aria-disabled", "true");
        });
    </script>
    <#if authenticationSession??>
        <script type="module">
             <#outputformat "JavaScript">
            import { checkAuthSession } from ${(url.resourcesPath + "/js/authChecker.js")?c};

            checkAuthSession(
                ${authenticationSession.authSessionIdHash?c}
            );
            </#outputformat>
        </script>
    </#if>
    <script>
      // Workaround for https://bugzilla.mozilla.org/show_bug.cgi?id=1404468
      const isFirefox = true;
    </script>
</head>

<body id="keycloak-bg" class="gtn ${properties.kcBodyClass!}" data-page-id="login-${pageId}">
<div class="gtn-shell">

  <#-- Form panel -->
  <main class="gtn-main">
    <div class="gtn-topbar">
      <a href="${backUrl?has_content?then(backUrl, siteUrl)}" class="gtn-brand gtn-brand--top">
        <@logoMark size=30 />
        <span>GoTravelNha</span>
      </a>
      <div class="gtn-topbar-actions">
        <#if realm.internationalizationEnabled && locale.supported?size gt 1>
          <label class="gtn-lang">
            <span class="gtn-visually-hidden">${msg("languages")}</span>
            <svg class="gtn-lang-icon" viewBox="0 0 20 20" fill="none" stroke="currentColor" aria-hidden="true">
              <circle cx="10" cy="10" r="7.5" stroke-width="1.6"/>
              <path d="M2.5 10h15M10 2.5c2 2.2 3 4.7 3 7.5s-1 5.3-3 7.5c-2-2.2-3-4.7-3-7.5s1-5.3 3-7.5Z" stroke-width="1.6"/>
            </svg>
            <select id="login-select-toggle" aria-label="${msg("languages")}" onchange="if (this.value) window.location.href=this.value">
              <#list locale.supported?sort_by("label") as l>
                <option value="${l.url}" ${(l.languageTag == locale.currentLanguageTag)?then('selected','')}>${l.label}</option>
              </#list>
            </select>
          </label>
        </#if>
        <#if backUrl?has_content>
          <a href="${backUrl}" class="gtn-back">
            <svg viewBox="0 0 20 20" fill="none" stroke="currentColor" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 10H4m0 0 5-5m-5 5 5 5" />
            </svg>
            ${msg("gtnBackToSite")}
          </a>
        </#if>
      </div>
    </div>

    <div class="gtn-center">
      <div class="gtn-card ${properties.kcLoginMainBody!}">
        <h1 class="gtn-title" id="kc-page-title"><#nested "header"></h1>
        <#assign description = gtnMsg("gtnDescription")>
        <#if description?has_content>
          <p class="gtn-description">${description}</p>
        </#if>

        <div class="gtn-body">
        <#if !(auth?has_content && auth.showUsername() && !auth.showResetCredentials())>
            <#if displayRequiredFields>
                <div class="${properties.kcContentWrapperClass!}">
                    <div class="${properties.kcLabelWrapperClass!} subtitle">
                        <span class="${properties.kcInputHelperTextItemTextClass!}">
                          <span class="${properties.kcInputRequiredClass!}">*</span> ${msg("requiredFields")}
                        </span>
                    </div>
                </div>
            </#if>
        <#else>
            <#if displayRequiredFields>
                <div class="${properties.kcContentWrapperClass!}">
                    <div class="${properties.kcLabelWrapperClass!} subtitle">
                        <span class="${properties.kcInputHelperTextItemTextClass!}">
                          <span class="${properties.kcInputRequiredClass!}">*</span> ${msg("requiredFields")}
                        </span>
                    </div>
                    <div class="${properties.kcFormClass} ${properties.kcContentWrapperClass}">
                        <#nested "show-username">
                        <@username />
                    </div>
                </div>
            <#else>
                <div class="${properties.kcFormClass} ${properties.kcContentWrapperClass}">
                  <#nested "show-username">
                  <@username />
                </div>
            </#if>
        </#if>

        <#-- App-initiated actions should not see warning messages about the need to complete the action during login. -->
        <#if displayMessage && message?has_content && (message.type != 'warning' || !isAppInitiatedAction??)>
            <div class="${properties.kcAlertClass!} pf-m-${(message.type = 'error')?then('danger', message.type)}" role="${(message.type = 'error')?then('alert', 'status')}">
                <div class="${properties.kcAlertIconClass!}">
                    <#if message.type = 'success'><span class="${properties.kcFeedbackSuccessIcon!}"></span></#if>
                    <#if message.type = 'warning'><span class="${properties.kcFeedbackWarningIcon!}"></span></#if>
                    <#if message.type = 'error'><span class="${properties.kcFeedbackErrorIcon!}"></span></#if>
                    <#if message.type = 'info'><span class="${properties.kcFeedbackInfoIcon!}"></span></#if>
                </div>
                <span class="${properties.kcAlertTitleClass!} kc-feedback-text">${message.summary}</span>
            </div>
        </#if>

        <#-- Social sign-in sits above the email form, like the web app's sign-in page. -->
        <#nested "socialProviders">

        <#nested "form">

        <#if auth?has_content && auth.showTryAnotherWayLink()>
          <form id="kc-select-try-another-way-form" action="${url.loginAction}" method="post" novalidate="novalidate">
              <input type="hidden" name="tryAnotherWay" value="on"/>
              <a id="try-another-way" href="javascript:document.forms['kc-select-try-another-way-form'].requestSubmit()"
                  class="${properties.kcButtonSecondaryClass} ${properties.kcButtonBlockClass} ${properties.kcMarginTopClass}">
                    ${msg("doTryAnotherWay")}
              </a>
          </form>
        </#if>

        <#if switchOrganizationEnabled?? && switchOrganizationEnabled>
          <form id="kc-switch-organization-form" action="${url.loginAction}" method="post" novalidate="novalidate">
              <input type="hidden" name="switchOrganization" value="true"/>
              <a id="switch-organization" href="javascript:document.forms['kc-switch-organization-form'].requestSubmit()"
                  class="${properties.kcButtonSecondaryClass} ${properties.kcButtonBlockClass} ${properties.kcMarginTopClass}">
                    ${msg("doSwitchOrganization")}
              </a>
          </form>
        </#if>

        <#if displayInfo>
            <div id="kc-info" class="gtn-info">
                <div id="kc-info-wrapper">
                    <#nested "info">
                </div>
            </div>
        </#if>
        </div>

        <@loginFooter.content/>
      </div>
    </div>

    <p class="gtn-legal">
      &copy; ${.now?string("yyyy")} GoTravelNha &middot;
      <a href="${siteUrl}/privacy">${msg("gtnPrivacy")}</a> &middot;
      <a href="${siteUrl}/terms">${msg("gtnTerms")}</a>
    </p>
  </main>

  <#-- Photo panel, desktop only. Decorative: the same message is in the page title for screen readers. -->
  <aside class="gtn-aside" aria-hidden="true" style="--gtn-aside-image: url('${url.resourcesPath}/img/${gtnImage()}')">
    <div class="gtn-aside-inner">
      <span class="gtn-brand gtn-brand--aside">
        <@logoMark size=34 />
        <span>GoTravelNha</span>
      </span>
      <div class="gtn-aside-copy">
        <h2>${gtnMsg("gtnHeadline")}</h2>
        <#assign subline = gtnMsg("gtnSubline")>
        <#if subline?has_content><p>${subline}</p></#if>
        <#assign points = gtnMsg("gtnPoints")>
        <#if points?has_content>
          <ul>
            <#list points?split("|") as point>
              <li>
                <span class="gtn-check">
                  <svg viewBox="0 0 20 20" fill="none" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="m5 10.5 3 3 7-7" /></svg>
                </span>
                ${point}
              </li>
            </#list>
          </ul>
        </#if>
      </div>
    </div>
  </aside>
</div>
<script src="${url.resourcesPath}/js/gtn-submit.js"></script>
</body>
</html>
</#macro>
