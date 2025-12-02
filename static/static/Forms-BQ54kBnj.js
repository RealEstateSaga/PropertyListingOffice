import{V as c,m as n,n as l}from"./index-BM-DvTdL.js";import{C as o}from"./CodeEditor-D58VTr3y.js";const p=c.extend({name:"ListForm",components:{"code-editor":o},data(){return{checked:[],html:""}},methods:{renderHTML(){let e=`<form method="post" action="${this.serverConfig.root_url}/subscription/form" class="listmonk-form">
  <div>
    <h3>${this.$t("public.sub")}</h3>
    <input type="hidden" name="nonce" />

    <p><input type="email" name="email" required placeholder="${this.$t("subscribers.email")}" /></p>
    <p><input type="text" name="name" placeholder="${this.$t("public.subName")}" /></p>

`;this.checked.forEach(t=>{const s=this.publicLists[parseInt(t,10)];e+=`    <p>
      <input id="${s.uuid.substr(0,5)}" type="checkbox" name="l" checked value="${s.uuid}" />
      <label for="${s.uuid.substr(0,5)}">${s.name}</label>
`,s.description&&(e+=`      <br />
      <span>${s.description}</span>
`),e+=`    </p>
`}),this.serverConfig.public_subscription.captcha_enabled&&(this.serverConfig.public_subscription.captcha_provider==="altcha"?e+=`
    <altcha-widget challengeurl="${this.serverConfig.root_url}/api/public/captcha/altcha"></altcha-widget>
    <script type="module" src="${this.serverConfig.root_url}/public/static/altcha.umd.js" async defer><\/script>
`:this.serverConfig.public_subscription.captcha_provider==="hcaptcha"&&(e+=`
    <div class="h-captcha" data-sitekey="${this.serverConfig.public_subscription.captcha_key}"></div>
    <script src="https://js.hcaptcha.com/1/api.js" async defer><\/script>
`)),e+=`
    <input type="submit" value="${this.$t("public.sub")} " />
  </div>
</form>`,this.html=e}},computed:{...n(["loading","lists","serverConfig"]),publicLists(){return this.lists.results?this.lists.results.filter(e=>e.type==="public"):[]}},watch:{checked(){this.renderHTML()}}});var u=function(){var t=this,s=t._self._c;return t._self._setupProxy,s("section",{staticClass:"forms content relative"},[s("h1",{staticClass:"title is-4"},[t._v(" "+t._s(t.$t("forms.title"))+" ")]),s("hr"),t.loading.lists?s("b-loading",{attrs:{active:t.loading.lists,"is-full-page":!1}}):t.publicLists.length===0?s("p",[t._v(" "+t._s(t.$t("forms.noPublicLists"))+" ")]):t.publicLists.length>0?s("div",{staticClass:"columns"},[s("div",{staticClass:"column is-4"},[s("h4",[t._v(t._s(t.$t("forms.publicLists")))]),s("p",[t._v(t._s(t.$t("forms.selectHelp")))]),s("b-loading",{attrs:{active:t.loading.lists,"is-full-page":!1}}),s("ul",{staticClass:"no",attrs:{"data-cy":"lists"}},t._l(t.publicLists,function(i,r){return s("li",{key:i.id},[s("b-checkbox",{attrs:{"native-value":r},model:{value:t.checked,callback:function(a){t.checked=a},expression:"checked"}},[t._v(" "+t._s(i.name)+" ")])],1)}),0),t.serverConfig.public_subscription.enabled?[s("hr"),s("h4",[t._v(t._s(t.$t("forms.publicSubPage")))]),s("p",[s("a",{attrs:{href:`${t.serverConfig.root_url}/subscription/form`,target:"_blank",rel:"noopener noreferer","data-cy":"url"}},[t._v(" "+t._s(t.serverConfig.root_url)+"/subscription/form ")])])]:t._e()],2),s("div",{staticClass:"column",attrs:{"data-cy":"form"}},[s("h4",[t._v(t._s(t.$t("forms.formHTML")))]),s("p",[t._v(" "+t._s(t.$t("forms.formHTMLHelp"))+" ")]),t.checked.length>0?s("code-editor",{attrs:{lang:"html",disabled:""},model:{value:t.html,callback:function(i){t.html=i},expression:"html"}}):t._e()],1)]):t._e()],1)},h=[],d=l(p,u,h);const _=d.exports;export{_ as default};
