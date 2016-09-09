(function(){var t,e,s=[].indexOf||function(t){for(var e=0,s=this.length;e<s;e++)if(e in this&&this[e]===t)return e;return-1};Array.prototype.select_resource_by_id=function(t){var e,s;return s=function(){var s,n,o;for(o=[],e=s=0,n=this.length;0<=n?s<n:s>n;e=0<=n?++s:--s)this[e].id===t&&o.push(this[e]);return o}.call(this)[0]},e={},e.ConstructResolver=function(){function t(t){this.constructs=t}return t.prototype.map={CcCondition:"Conditions",CcLoop:"Loops",CcQuestion:"Questions",CcSequence:"Sequences",CcStatement:"Statements"},t.prototype.resolve=function(t,e){var n,o,r,i,u,c,l;null==t&&(t=["Conditions","Loops","Sequences"]),null==e&&(e=["Conditions","Loops","Questions","Sequences","Statements"]),c=this.constructs,l=[];for(u in c)o=c[u],s.call(t,u)>=0?l.push(function(){var t,e,s,u,c,l,h,a,p;for(p=[],t=0,u=o.length;t<u;t++){for(r=o[t],h=r.children,i=e=0,c=h.length;e<c;i=++e)n=h[i],null!=n.type&&n.type in this.map&&(r.children[i]=this.constructs[this.map[n.type]].select_resource_by_id(n.id));if(null!=r.fchildren)for(a=r.fchildren,i=s=0,l=a.length;s<l;i=++s)n=a[i],null!=n.type&&n.type in this.map&&(r.fchildren[i]=this.constructs[this.map[n.type]].select_resource_by_id(n.id));p.push(r.resolved=!0)}return p}.call(this)):l.push(void 0);return l},t}(),e.QuestionResolver=function(){function t(t){this.questions=t}return t.prototype.map={QuestionItem:"Items",QuestionGrid:"Grids"},t.prototype.resolve=function(t){var e,s,n,o,r,i;for(i=[],o=n=0,r=t.length;n<r;o=++n)s=t[o],i.push(null!=(e=t[o]).base?e.base:e.base=this.questions[this.map[s.question_type]].select_resource_by_id(s.question_id));return i},t}(),e.CodeResolver=function(){function t(t,e){this.code_lists=t,this.categories=e}return t.prototype.category=function(t){return this.categories.select_resource_by_id(t.category_id)},t.prototype.resolve=function(){var t,e,s,n,o,r,i;for(r=this.code_lists,i=[],s=0,o=r.length;s<o;s++)e=r[s],i.push(function(){var s,o,r,i;for(r=e.codes,i=[],n=s=0,o=r.length;s<o;n=++s)t=r[n],i.push(e.codes[n].label=this.category(t).label);return i}.call(this));return i},t}(),e.GroupResolver=function(){function t(t,e){this.groups=t,this.users=e}return t.prototype.resolve=function(){var t,e,s,n,o,r,i,u;for(o=this.groups,r=[],e=s=0,n=o.length;s<n;e=++s)t=o[e],this.groups[e].users=[],r.push(function(){var s,n,o,r;for(o=this.users,r=[],u=s=0,n=o.length;s<n;u=++s)i=o[u],t.id===i.group_id?(this.users[u].group=t.label,r.push(this.groups[e].users.push(i))):r.push(void 0);return r}.call(this));return r},t}(),t=function(t){var s,n,o,r,i,u,c,l;for(o=t.data.data,u=t.data.options,l=Array.isArray(t.data.type)?t.data.type:[t.data.type],r=0,i=l.length;r<i;r++)c=l[r],console.time("resolving"),"constructs"===c?(s=new e.ConstructResolver(o.Constructs),s.resolve(u)):"questions"===c&&(n=new e.QuestionResolver(o.Questions),n.resolve(o.Constructs.Questions)),console.timeEnd("resolving");return this.postMessage(o)},self.addEventListener("message",t)}).call(this);