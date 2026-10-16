<#--
  Based on keycloak.v2/login/social-providers.ftl (Keycloak 26.8.1). The template renders this ABOVE the
  email form, so the divider ("or sign in with email") comes after the buttons instead of before them.
-->
<#import "divider.ftl" as divider>
<#macro show social>
  <#assign useGrid = (social.providers?size gt 3)>
  <div id="kc-social-providers" class="${properties.kcFormSocialAccountSectionClass!}">
      <ul class="${properties.kcFormSocialAccountListClass!} <#if useGrid>${properties.kcFormSocialAccountListGridClass!}</#if>">
          <#list social.providers as p>
              <li class="<#if useGrid>${properties.kcFormSocialAccountGridItem!}<#else>${properties.kcFormSocialAccountListItemClass!}</#if>">
                  <a data-once-link data-disabled-class="${properties.kcFormSocialAccountListButtonDisabledClass!}" id="social-${p.alias}"
                          class="${properties.kcFormSocialAccountListButtonClass!}" aria-label="<#if useGrid>${p.displayName!}<#else>${msg("signInWithProvider", p.displayName!)}</#if>"
                          type="button" href="${p.loginUrl}">
                        <#if p.iconClasses?has_content && p.providerId != "google">
                            <span class="${p.iconClasses!}"></span>
                        <#else>
                            <#switch p.providerId>
                                <#case "github">
                                <#case "instagram">
                                <#case "twitter">
                                <#case "google">
                                <#case "facebook">
                                <#case "gitlab">
                                <#case "linkedin-openid-connect">
                                <#case "microsoft">
                                <#case "bitbucket">
                                <#case "stackoverflow">
                                <#case "paypal">
                                <#case "openshift-v4">
                                    <img src="${url.resourcesPath}/img/social/${p.providerId}.svg" aria-hidden="true" alt="">
                                    <#break>
                                <#default>
                                    <img src="${url.resourcesPath}/img/social/default.svg" aria-hidden="true" alt="">
                            </#switch>
                        </#if>
                        <span class="${properties.kcFormSocialAccountNameClass!}"><#if useGrid>${p.displayName!}<#else>${msg("gtnContinueWith", p.displayName!)}</#if></span>
                  </a>
              </li>
          </#list>
      </ul>
  </div>
  <@divider.or text=msg((pageId == "register")?then("gtnEmailDividerRegister", "gtnEmailDivider")) />
</#macro>
