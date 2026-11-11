(function () {
  var I18N = {
    en: {
      'nav.why': 'Why', 'nav.contract': 'Contract', 'nav.schema': 'Schema', 'nav.lifecycle': 'Lifecycle', 'nav.start': 'Quick start',
      'hero.eyebrow': 'Contract v1 · Canonical bytes · MIT',
      'hero.title': 'One contract.\nEvery runtime.',
      'hero.lede': 'Keel is the transport-neutral application contract shared by Racket desktop runtimes: one value model, one canonical encoding, one error shape — so native and WebView apps speak the same bytes.',
      'hero.start': 'Get started', 'hero.spec': 'Read Contract v1',
      'proof.neutral': 'Transport-neutral', 'proof.canonical': 'Canonical bytes', 'proof.bounded': 'Bounded resources',
      'value.label': 'CANONICAL VALUE', 'value.verified': 'canonical', 'value.budget': 'max encoded value',
      'value.rivet': 'byte-identical', 'value.glaze': 'same bytes',
      'why.eyebrow': 'BELOW THE PROTOCOL, ABOVE THE BYTES', 'why.title': 'Envelopes differ. Meaning shouldn\'t.',
      'why.p1': 'RVT1 frames a native RPC; GLZ1 frames a WebView invoke. Frames, request ids, and backpressure are transport business — but the payload they carry kept being redefined by each runtime.',
      'why.p2': 'Keel owns what travels inside: values, structured errors, lifecycle names, and a schema vocabulary. It sits above a byte stream and below an application protocol, so Rivet and Glaze embed one contract instead of maintaining two.',
      'principle.one.title': 'Canonical by construction',
      'principle.one.body': 'One value encodes to one byte sequence. Map keys are ordered by their UTF-8 bytes, non-finite floats are rejected, and decoders refuse anything non-canonical.',
      'principle.two.title': 'Transport-neutral',
      'principle.two.body': 'A schema describes records, commands, events, and states without owning an envelope: Rivet maps a command to an RVT1 RPC, Glaze to a GLZ1 invoke. Names like ready? stay exact.',
      'principle.three.title': 'Bounded resources',
      'principle.three.body': 'Every implementation enforces the same budgets — 64 MiB, depth 64, 262,144 nodes — and rejects the same malformed inputs. No runtime is more forgiving than another.',
      'contract.eyebrow': 'TEN TAGS, NO AMBIGUITY', 'contract.title': 'The whole value union fits in one nibble.',
      'contract.lede': 'Every value is one tag byte followed by a fixed body. Integers are little-endian; lengths are unsigned 32-bit.',
      'contract.value': 'Value', 'contract.body': 'Body', 'contract.empty': 'none',
      'contract.int': 'signed two\'s-complement, little-endian',
      'contract.str': 'length + well-formed UTF-8',
      'contract.bytes': 'length + uninterpreted bytes',
      'contract.list': 'item count + encoded values',
      'contract.float': 'finite IEEE-754 binary64 bits',
      'contract.map': 'entry count + String pairs, keys sorted',
      'contract.error': 'code + message + data value',
      'contract.note': 'Error codes are kebab-case and deliberately not a closed list — RVT1, GLZ1, and future transports each publish and negotiate their own taxonomy.',
      'budget.value': 'max encoded value', 'budget.depth': 'max nesting depth', 'budget.nodes': 'max value nodes',
      'lifecycle.eyebrow': 'ONE VOCABULARY, TERMINAL ENDS', 'lifecycle.title': 'Every runtime says the same words.',
      'lifecycle.starting': 'bootstrapping', 'lifecycle.ready': 'accepting work', 'lifecycle.running': 'steady state',
      'lifecycle.stopping': 'draining', 'lifecycle.stopped': 'terminal',
      'lifecycle.note': 'Early shutdown may jump from starting or ready straight to stopping. Success, failure, cancellation, and timeout are mutually exclusive outcomes — cancellation races completion, and the winner owns the single terminal result.',
      'start.eyebrow': 'RACKET REFERENCE IMPLEMENTATION', 'start.title': 'From value to bytes.',
      'start.lede': 'Install the package, encode a value, get the canonical bytes — the same bytes every conforming runtime produces.',
      'start.spec': 'Read the normative Contract v1 →',
      'discipline.eyebrow': 'COMPATIBILITY DISCIPLINE', 'discipline.title': 'Golden bytes never change.',
      'discipline.body': 'tests/golden-v1.txt is the normative byte corpus: changing an existing line is a compatibility break. New union members need a written rationale, new cross-runtime golden vectors, decoder budget tests, and a version decision.',
      'boundary.eyebrow': 'A DELIBERATE BOUNDARY', 'boundary.title': 'A contract, not a transport.',
      'boundary.body': 'Keel owns no frame header, request identifier, streaming or backpressure, renderer, permission model, or installer. Rivet keeps RVT1 and its native hosts; Glaze keeps GLZ1 and its WebView adapters; other transports may embed this codec but negotiate their own versions and error taxonomies.',
      'schema.eyebrow': 'DESCRIBE THE BOUNDARY, COMPARE THE CHANGE',
      'schema.title': 'One schema language. Honest compatibility.',
      'schema.lede': 'Records, enums, commands, events, and states describe the application boundary without selecting a transport — and any two revisions can be compared, rule by rule.',
      'schema.p1': 'A schema is itself data: canonical bytes any runtime can read. Rivet maps a command to an RVT1 RPC, Glaze to a GLZ1 invoke; the description travels with the application, not with the frame.',
      'schema.breaking.verdict': 'BREAKING',
      'schema.breaking.title': 'A peer can observe the difference',
      'schema.breaking.body': 'Removing a record, field, enum case, command, parameter, or declared error code — or changing any type — is reported as breaking, at a stable dotted path.',
      'schema.compatible.verdict': 'COMPATIBLE',
      'schema.compatible.title': 'Old peers keep operating',
      'schema.compatible.body': 'Adding a record, enum, command, event, state, or an optional field is compatible. schema-compatible? answers with one boolean; every difference is reviewable.',
      'schema.note': 'Revision numbers are not interpreted: callers decide whether a revision replaces, supersedes, or accompanies the old one.',
      'footer.tagline': 'The shared application contract of the Racket desktop family.'
    },
    zh: {
      'nav.why': '为什么', 'nav.contract': '契约', 'nav.schema': 'Schema', 'nav.lifecycle': '生命周期', 'nav.start': '快速开始',
      'hero.eyebrow': 'Contract v1 · 规范字节 · MIT',
      'hero.title': '一份契约，\n每个运行时。',
      'hero.lede': 'Keel 是 Racket 桌面运行时共享的传输无关应用契约：一个值模型、一套规范编码、一个错误形状——原生渲染与 WebView 渲染两端，说的是同一种字节。',
      'hero.start': '快速开始', 'hero.spec': '阅读 Contract v1',
      'proof.neutral': '传输无关', 'proof.canonical': '规范字节', 'proof.bounded': '有界资源',
      'value.label': '规范值', 'value.verified': '规范', 'value.budget': '编码值上限',
      'value.rivet': '字节一致', 'value.glaze': '同一份字节',
      'why.eyebrow': '协议之下，字节之上', 'why.title': '信封可以不同，含义必须一致。',
      'why.p1': 'RVT1 装帧原生 RPC，GLZ1 装帧 WebView invoke——帧、请求 id、背压都是传输的事；但帧里装的东西，过去每个运行时都在各定义各的。',
      'why.p2': 'Keel 只管装在里面的部分：值、结构化错误、生命周期词汇和模式描述语言。它坐在字节流之上、应用协议之下，Rivet 和 Glaze 嵌入同一份契约，而不是各自维护两套。',
      'principle.one.title': '构造即规范',
      'principle.one.body': '一个值只有一种字节序列。Map 键按 UTF-8 字节排序，非有限浮点数直接拒绝，解码端拒绝任何不规范输入。',
      'principle.two.title': '传输无关',
      'principle.two.body': '模式只描述记录、命令、事件和状态，不拥有信封：同一个命令，Rivet 映射成 RVT1 RPC，Glaze 映射成 GLZ1 invoke。ready? 这样的 Racket 命名原样保留。',
      'principle.three.title': '资源有界',
      'principle.three.body': '所有实现执行同一套预算——64 MiB、深度 64、262,144 节点——并拒绝同样的畸形输入。没有哪个运行时更宽容。',
      'contract.eyebrow': '十个标签，没有歧义', 'contract.title': '整个值联合，一个 nibble 装得下。',
      'contract.lede': '每个值 = 一个标签字节 + 固定正文。整数小端序，长度为无符号 32 位。',
      'contract.value': '值', 'contract.body': '正文', 'contract.empty': '无',
      'contract.int': '有符号二补码，小端序',
      'contract.str': '长度 + 良构 UTF-8',
      'contract.bytes': '长度 + 不解释的字节',
      'contract.list': '元素数 + 逐个编码的值',
      'contract.float': '有限 IEEE-754 binary64 位型',
      'contract.map': '条目数 + String 键值对，键有序',
      'contract.error': 'code + message + data 值',
      'contract.note': '错误码是 kebab-case，且刻意不做封闭清单——RVT1、GLZ1 和未来的传输各自发布、协商自己的错误分类。',
      'budget.value': '编码值上限', 'budget.depth': '最大嵌套深度', 'budget.nodes': '最大值节点数',
      'lifecycle.eyebrow': '一套词汇，终点明确', 'lifecycle.title': '所有运行时说同一种话。',
      'lifecycle.starting': '启动中', 'lifecycle.ready': '可接活', 'lifecycle.running': '稳态运行',
      'lifecycle.stopping': '排水收尾', 'lifecycle.stopped': '终态',
      'lifecycle.note': '提前关停可以从 starting 或 ready 直接跳到 stopping。成功、失败、取消、超时互斥成立——取消与完成赛跑，赢家独占唯一的终局结果。',
      'start.eyebrow': 'RACKET 参考实现', 'start.title': '从值到字节。',
      'start.lede': '装上包，编码一个值，得到规范字节——所有合规运行时产出的都是同一份。',
      'start.spec': '阅读规范文档 Contract v1 →',
      'discipline.eyebrow': '兼容性纪律', 'discipline.title': 'golden 字节不动。',
      'discipline.body': 'tests/golden-v1.txt 是规范的字节语料：改动任何已有行都算兼容性破坏。新增联合成员需要书面论证、新的跨运行时 golden 向量、解码预算测试和一次版本决策。',
      'boundary.eyebrow': '有意保留的边界', 'boundary.title': '是契约，不是传输。',
      'boundary.body': 'Keel 不拥有帧头、请求标识、流式与背压、渲染器、权限模型或安装器。Rivet 保留 RVT1 和它的原生宿主；Glaze 保留 GLZ1 和它的 WebView 适配器；其他传输可以嵌入这套编解码，但版本与错误分类自行协商。',
      'schema.eyebrow': '描述边界，如实比较',
      'schema.title': '一套 schema 语言，诚实的兼容性。',
      'schema.lede': '记录、枚举、命令、事件与状态只描述应用边界，不选定传输——任意两个版本都能逐条规则比较。',
      'schema.p1': 'Schema 本身也是数据：任何运行时都能读的规范字节。Rivet 把命令映射成 RVT1 RPC，Glaze 映射成 GLZ1 invoke；描述跟着应用走，不跟着帧走。',
      'schema.breaking.verdict': 'BREAKING',
      'schema.breaking.title': '对端能察觉的差异',
      'schema.breaking.body': '删除记录、字段、枚举分支、命令、参数或已声明的错误码，或改变任何类型——都会按稳定的点分路径报告为 breaking。',
      'schema.compatible.verdict': 'COMPATIBLE',
      'schema.compatible.title': '老对端继续工作',
      'schema.compatible.body': '新增记录、枚举、命令、事件、状态或可选字段都是兼容的。schema-compatible? 给出一个布尔答案，每一条差异都可评审。',
      'schema.note': '版本号本身不被解释：新版本是替换、取代还是并存，由调用方决定。',
      'footer.tagline': 'Racket 桌面家族共享的应用契约。'
    }
  };

  function language() {
    return document.documentElement.lang === 'zh-CN' ? 'zh' : 'en';
  }

  function applyLanguage(lang) {
    document.documentElement.lang = lang === 'zh' ? 'zh-CN' : 'en';
    document.querySelectorAll('[data-i18n]').forEach(function (element) {
      var value = I18N[lang][element.dataset.i18n];
      if (value) {
        if (element.dataset.i18n === 'hero.title') {
          element.innerHTML = value.replace('\n', '<br>');
        } else {
          element.textContent = value;
        }
      }
    });
    document.getElementById('lang-button').textContent = lang === 'zh' ? 'EN' : '中文';
    localStorage.setItem('keel-lang', lang);
  }

  document.getElementById('lang-button').addEventListener('click', function () {
    applyLanguage(language() === 'zh' ? 'en' : 'zh');
  });

  document.getElementById('theme-button').addEventListener('click', function () {
    var next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    localStorage.setItem('keel-theme', next);
  });

  applyLanguage(language());
})();
