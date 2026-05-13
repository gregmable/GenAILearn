(function () {
  // ── Storage keys ──────────────────────────────────────────────────────
  var storageKey = "genai-learning-quiz-progress";
  var visitedKey  = "genai-learning-visited";
  var authKey = "genai-learning-auth";
  var sessionKey = "genai-learning-session";
  var QUIZ_PER_SET = 5; // randomly drawn from the full bank each attempt
  var currentFileName = getCurrentFileName();
  var currentUser = null;

  // ── Quiz dependency chain ──────────────────────────────────────────────
  var quizOrder = ["phase1", "phase2", "phase3"];
  var quizDependencies = { phase1: null, phase2: "phase1", phase3: "phase2" };

  // ── Quiz question bank (10 per phase; 5 randomly selected per attempt) ─
  var quizData = {
    phase1: [
      { question: "What is the primary difference between Generative AI and Analytical AI?", options: ["Generative AI makes predictions while Analytical AI creates new content", "Generative AI creates new content while Analytical AI makes predictions and decisions", "They are the same thing with different names", "Generative AI only works with text while Analytical AI works with numbers", "Generative AI is faster than Analytical AI"], correct: 1, why: "Generative AI creates new content, while analytical AI supports prediction and decisioning." },
      { question: "Which training stage uses reinforcement learning from human feedback (RLHF)?", options: ["Pretraining only", "Inference only", "Supervised fine-tuning (SFT) and alignment with human preferences", "Tokenization stage", "Context window expansion"], correct: 2, why: "RLHF is used during alignment after pretraining, together with SFT, to tune outputs toward human preferences." },
      { question: "Approximately how many tokens equal one word in most LLM tokenization schemes?", options: ["1 token equals 1 word exactly", "1 token equals approximately three-quarters of a word", "1 token equals 2 words", "1 token equals half a word", "Token count is unrelated to word count"], correct: 1, why: "A common estimate is about 1 token for every three-quarters of a word." },
      { question: "In Pega Infinity '25, which model is designated as 'Smart' for AWS Bedrock?", options: ["Claude Haiku 3", "Gemini Flash 2", "GPT-4o mini", "Claude Sonnet 3.7", "Gemini Pro 1.5"], correct: 3, why: "The deck identifies Claude Sonnet 3.7 as the AWS Bedrock 'Smart' option." },
      { question: "What does higher temperature setting produce in LLM outputs?", options: ["Faster processing speed", "More creative and diverse outputs", "More focused and predictable outputs", "Lower token costs", "Better grammar and spelling"], correct: 1, why: "Higher temperature increases randomness, which usually makes outputs more varied and creative." },
      { question: "What is an LLM 'context window'?", options: ["The number of users who can query the model simultaneously", "The maximum amount of text (in tokens) a model can process in a single request", "The time it takes to generate a response", "The list of supported programming languages", "The size of the training dataset"], correct: 1, why: "The context window is the total number of tokens (input + output) a model can handle in one request." },
      { question: "What is 'fine-tuning' in the context of large language models?", options: ["Adjusting the temperature parameter at inference time", "Further training a pre-trained model on a smaller domain-specific dataset", "Removing unnecessary tokens from a prompt", "Compressing the model weights for faster inference", "Running the model on specialized hardware"], correct: 1, why: "Fine-tuning adapts a pre-trained base model to a specific domain or task using additional labeled data." },
      { question: "What is an LLM 'hallucination'?", options: ["A model producing extremely slow responses", "A model confidently generating factually incorrect or fabricated information", "A model refusing to answer a question", "A model producing excessively long outputs", "A security vulnerability in the model API"], correct: 1, why: "Hallucination refers to the model generating plausible-sounding but incorrect or invented content." },
      { question: "Which prompt engineering technique involves providing examples of input-output pairs directly in the prompt?", options: ["Zero-shot prompting", "Chain-of-thought prompting", "Few-shot prompting", "System prompting", "Temperature tuning"], correct: 2, why: "Few-shot prompting includes example input-output pairs in the prompt so the model can learn the pattern in-context." },
      { question: "What is Pega's primary principle for responsible AI deployment?", options: ["Maximize throughput above all else", "Ethical AI with human oversight and governance", "Deploy all AI with zero human review", "Use only open-source models", "AI decisions must never be explained"], correct: 1, why: "Pega emphasizes ethical, governed AI with human oversight as core to responsible enterprise AI." }
    ],
    phase2: [
      { question: "What does RAG stand for in GenAI architecture?", options: ["Rapid Agent Generation", "Retrieval Augmented Generation", "Reinforcement Adaptive Grounding", "Random Access Gateway", "Recursive Algorithm Generation"], correct: 1, why: "RAG means Retrieval Augmented Generation and grounds model responses in retrieved source content." },
      { question: "What analogy is used to describe the Model Context Protocol (MCP)?", options: ["The WiFi for AI", "The Bluetooth for AI", "The USB-C for AI", "The Ethernet for AI", "The HDMI for AI"], correct: 2, why: "The presentation calls MCP 'the USB-C for AI' because it standardizes access to tools and data." },
      { question: "Which protocol is used for peer-to-peer agent collaboration in Pega's multi-agent systems?", options: ["MCP (Model Context Protocol)", "HTTP", "A2A (Agent-to-Agent)", "REST API", "GraphQL"], correct: 2, why: "A2A is used for agent collaboration, while MCP is for tool and data access." },
      { question: "How many languages does Pega's content filtering support for harmful content detection?", options: ["4 languages", "6 languages", "8 languages", "10 languages", "12 languages"], correct: 2, why: "The deck states Pega content filtering supports 8 languages." },
      { question: "What is the recommended practice for validating GenAI outputs in production?", options: ["Automated testing only", "Human-in-the-loop (HITL) evaluation", "No validation needed", "Use only judge agents", "Rely on model confidence scores"], correct: 1, why: "HITL validation is recommended so humans can review outputs before or during production use." },
      { question: "What does 'chunking' refer to in a RAG pipeline?", options: ["Dividing a model's weights into smaller files for distribution", "Splitting source documents into smaller text segments for indexing and retrieval", "Grouping users by query type", "Batching inference requests for efficiency", "Compressing embeddings for storage"], correct: 1, why: "Chunking splits source documents into manageable segments so they can be embedded and retrieved effectively." },
      { question: "What is a vector embedding?", options: ["A compressed image format for AI training data", "A numerical representation of text that captures semantic meaning in multi-dimensional space", "A hardware accelerator for LLMs", "A type of prompt template", "A log format for GenAI telemetry"], correct: 1, why: "Vector embeddings convert text to numeric vectors that capture semantic similarity, enabling similarity search in RAG." },
      { question: "What is the purpose of a semantic cache in a GenAI deployment?", options: ["Storing user session cookies", "Returning a previously computed answer when a new query is semantically similar to a cached one", "Encrypting model responses at rest", "Splitting large prompts into smaller chunks", "Logging all model outputs for audit"], correct: 1, why: "Semantic caching stores previous responses keyed by meaning, not exact text, reducing redundant LLM calls." },
      { question: "Which type of attack attempts to override a model's system instructions through user input?", options: ["SQL injection", "Prompt injection", "Cross-site scripting", "Man-in-the-middle", "Buffer overflow"], correct: 1, why: "Prompt injection attacks embed malicious instructions in user input to manipulate the model's behavior." },
      { question: "What metric measures whether a RAG-generated answer is factually supported by the retrieved source documents?", options: ["Latency", "Faithfulness / groundedness", "Token throughput", "Context window utilization", "Embedding cosine distance"], correct: 1, why: "Faithfulness (groundedness) measures whether the generated answer is actually supported by the retrieved source material." }
    ],
    phase3: [
      { question: "How many layers are in Pega's GenAI architecture?", options: ["Two layers", "Three layers", "Four layers", "Five layers", "Six layers"], correct: 2, why: "Pega's GenAI architecture is described as a four-layer model." },
      { question: "Which Pega GenAI product uses RAG to answer questions from client content?", options: ["Autopilot", "Blueprint", "Knowledge Buddy", "Coach", "AgentX API"], correct: 2, why: "Knowledge Buddy is the RAG-based assistant for answering from client content." },
      { question: "What was the Pega GenAI Gateway service introduced in?", options: ["Infinity '21", "Infinity '22", "Infinity '23", "Infinity '24", "Infinity '25"], correct: 2, why: "The material says the Gateway service was introduced in Infinity '23." },
      { question: "Which Pega product enables collaborative application design with AI-assisted workflow creation?", options: ["Autopilot", "Blueprint", "Knowledge Buddy", "Coach", "Connect"], correct: 1, why: "Blueprint is the collaborative AI-assisted design tool for application and workflow creation." },
      { question: "What connectivity mechanism enables client-managed deployments to access Pega Cloud-hosted GenAI services?", options: ["CloudConnect", "PremBridge", "GenAI Gateway", "Direct API", "VPN Tunnel"], correct: 1, why: "PremBridge provides secure connectivity between client-managed deployments and Pega Cloud-hosted GenAI services." },
      { question: "What is Pega Autopilot's primary function?", options: ["Managing database queries", "Providing AI-driven automation that executes case work autonomously within defined guardrails", "Generating marketing content", "Training custom LLMs on client data", "Load-balancing LLM requests"], correct: 1, why: "Autopilot autonomously drives case work forward using AI, with human oversight at configurable control points." },
      { question: "What does a GenAI Center of Excellence (CoE) primarily govern?", options: ["Hardware procurement for GPU clusters", "Standards, policies, and oversight for enterprise-wide GenAI adoption and risk management", "Writing all prompts for every business unit", "Deploying the LLM training infrastructure", "Managing vendor SLAs for cloud storage"], correct: 1, why: "A CoE establishes governance frameworks, standards, and policies for responsible enterprise GenAI adoption." },
      { question: "What does Pega's AgentX framework enable in multi-agent systems?", options: ["GPU scheduling for LLM inference", "Orchestrating multiple specialized AI agents that collaborate to handle complex tasks", "Fine-tuning Pega-specific LLMs", "Encrypting agent-to-agent communication", "Managing cloud billing for AI services"], correct: 1, why: "AgentX orchestrates specialized agents that work together, each handling a domain-specific part of a complex workflow." },
      { question: "Which Pega product provides next-best-action recommendations for customer service agents?", options: ["Blueprint", "Knowledge Buddy", "Pega Customer Decision Hub (CDH)", "PremBridge", "AgentX"], correct: 2, why: "Pega Customer Decision Hub (CDH) is the decisioning engine that surfaces next-best-action recommendations in real time." },
      { question: "In a hybrid LLM deployment, what is the main advantage of keeping a smaller local model on-premises?", options: ["It always produces higher-quality outputs than cloud models", "It reduces latency and keeps sensitive data from leaving the organization's environment", "It is cheaper to train than cloud-hosted models", "It supports larger context windows than cloud models", "It requires no prompting or configuration"], correct: 1, why: "On-premises/local models keep data in-house and reduce round-trip latency, which is critical for sensitive workloads." }
    ]
  };
  var pageSequence = [
    { file: "phase1-1.html", label: "1.1 GenAI Fundamentals & Pega's AI Vision", phase: "phase1" },
    { file: "phase1-2.html", label: "1.2 Large Language Models (LLMs) & Architecture", phase: "phase1" },
    { file: "phase1-3.html", label: "1.3 Prompt Engineering Fundamentals", phase: "phase1" },
    { file: "phase1-4.html", label: "1.4 Retrieval-Augmented Generation (RAG)", phase: "phase1" },
    { file: "phase1-5.html", label: "1.5 Pega GenAI Product Portfolio Overview", phase: "phase1" },
    { file: "phase1-6.html", label: "1.6 AI Ethics, Governance & Responsible AI", phase: "phase1" },
    { file: "phase1-quiz.html", label: "Phase 1 Knowledge Quiz", quizKey: "phase1", phase: "phase1" },
    { file: "phase2-1.html", label: "2.1 Building RAG Pipelines in Pega", phase: "phase2" },
    { file: "phase2-2.html", label: "2.2 MCP & Agent-to-Agent (A2A) Protocols", phase: "phase2" },
    { file: "phase2-3.html", label: "2.3 Enterprise GenAI Tooling & Platform Evaluation", phase: "phase2" },
    { file: "phase2-4.html", label: "2.4 GenAI Quality Evaluation & Testing", phase: "phase2" },
    { file: "phase2-5.html", label: "2.5 Observability & Monitoring for GenAI", phase: "phase2" },
    { file: "phase2-6.html", label: "2.6 GenAI Security & Data Protection", phase: "phase2" },
    { file: "phase2-quiz.html", label: "Phase 2 Knowledge Quiz", quizKey: "phase2", phase: "phase2" },
    { file: "phase3-1.html", label: "3.1 Pega GenAI Architecture Patterns", phase: "phase3" },
    { file: "phase3-2.html", label: "3.2 Deep Dive: Pega GenAI Product Suite", phase: "phase3" },
    { file: "phase3-3.html", label: "3.3 LLM Integration Paths & On-Premises Options", phase: "phase3" },
    { file: "phase3-4.html", label: "3.4 Multi-Agent Systems & AgentX Framework", phase: "phase3" },
    { file: "phase3-5.html", label: "3.5 GenAI Connect: Configuration & Walkthrough", phase: "phase3" },
    { file: "phase3-6.html", label: "3.6 CoE Best Practices & Enterprise Governance", phase: "phase3" },
    { file: "phase3-7.html", label: "3.7 Production Deployment & Enablement Requirements", phase: "phase3" },
    { file: "phase3-quiz.html", label: "Phase 3 Knowledge Quiz", quizKey: "phase3", phase: "phase3" }
  ];

  // ── Helpers ────────────────────────────────────────────────────────────
  function getCurrentFileName() {
    var path = window.location.pathname.split("/");
    var file = path[path.length - 1];
    return file || "index.html";
  }

  function shuffleArray(arr) {
    var a = arr.slice();
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
    }
    return a;
  }

  function getLoginReturnTarget() {
    return encodeURIComponent(currentFileName || "index.html");
  }

  function loadAuthStore() {
    try {
      var raw = localStorage.getItem(authKey);
      var data = raw ? JSON.parse(raw) : null;
      if (!data || typeof data !== "object") {
        return { users: {}, lastUser: "" };
      }
      if (!data.users || typeof data.users !== "object") data.users = {};
      if (typeof data.lastUser !== "string") data.lastUser = "";
      return data;
    } catch (e) {
      return { users: {}, lastUser: "" };
    }
  }

  function saveAuthStore(store) {
    try { localStorage.setItem(authKey, JSON.stringify(store)); } catch (e) {}
  }

  function loadSession() {
    try {
      var raw = localStorage.getItem(sessionKey);
      var data = raw ? JSON.parse(raw) : null;
      return data && typeof data.user === "string" ? data : { user: "" };
    } catch (e) {
      return { user: "" };
    }
  }

  function saveSession(userName) {
    try { localStorage.setItem(sessionKey, JSON.stringify({ user: userName || "" })); } catch (e) {}
  }

  function normalizeUserName(name) {
    return (name || "").trim().toLowerCase();
  }

  function getActiveUserRecord() {
    var store = loadAuthStore();
    var session = loadSession();
    var key = normalizeUserName(session.user);
    if (!key || !store.users[key]) return null;
    return { key: key, profile: store.users[key], store: store };
  }

  function getProgressStorageKey(baseKey) {
    if (!currentUser || !currentUser.key) return baseKey;
    return baseKey + "::" + currentUser.key;
  }

  function redirectToLogin() {
    var target = "login.html?returnTo=" + getLoginReturnTarget();
    window.location.replace(target);
  }

  function readReturnTarget() {
    try {
      var params = new URLSearchParams(window.location.search || "");
      var target = params.get("returnTo") || "index.html";
      if (!target || target.indexOf("login.html") !== -1) return "index.html";
      return target;
    } catch (e) {
      return "index.html";
    }
  }

  function setupAuthPage() {
    var form = document.querySelector("[data-auth-form]");
    if (!form) return;
    var nameEl = form.querySelector("[data-auth-name]");
    var passEl = form.querySelector("[data-auth-pass]");
    var errorEl = form.querySelector("[data-auth-error]");
    var submitEl = form.querySelector("[data-auth-submit]");
    var returnTarget = readReturnTarget();
    var active = getActiveUserRecord();

    if (active && nameEl && !nameEl.value) {
      nameEl.value = active.profile.displayName || active.key;
    }

    function showError(msg) {
      if (!errorEl) return;
      errorEl.textContent = msg || "";
      errorEl.hidden = !msg;
    }

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var name = nameEl ? nameEl.value.trim() : "";
      var password = passEl ? passEl.value : "";
      var key = normalizeUserName(name);
      if (!name || !password || !key) {
        showError("Please enter both name and password.");
        return;
      }

      var store = loadAuthStore();
      var existing = store.users[key];
      if (existing && existing.password !== password) {
        showError("Invalid password for this user.");
        return;
      }
      if (!existing) {
        store.users[key] = { displayName: name, password: password };
      } else if (!existing.displayName) {
        existing.displayName = name;
      }

      store.lastUser = key;
      saveAuthStore(store);
      saveSession(key);
      if (submitEl) submitEl.disabled = true;
      window.location.replace(returnTarget || "index.html");
    });
  }

  function setupAccountControls() {
    if (!currentUser || !currentUser.profile) return;
    var navLinks = document.querySelector(".nav-links");
    if (!navLinks) return;
    var accountLi = document.createElement("li");
    var displayName = currentUser.profile.displayName || currentUser.key;
    accountLi.innerHTML = "<a href=\"#\" data-auth-logout=\"true\">" + displayName + " (Logout)</a>";
    navLinks.appendChild(accountLi);
    var logoutLink = accountLi.querySelector("[data-auth-logout]");
    if (!logoutLink) return;
    logoutLink.addEventListener("click", function (event) {
      event.preventDefault();
      saveSession("");
      redirectToLogin();
    });
  }

  function enforceAuth() {
    if (currentFileName === "login.html") {
      setupAuthPage();
      return false;
    }
    currentUser = getActiveUserRecord();
    if (!currentUser) {
      redirectToLogin();
      return false;
    }
    return true;
  }

  if (!enforceAuth()) return;

  // ── Quiz pass state ────────────────────────────────────────────────────
  function loadState() {
    var def = { phase1: { passed: false }, phase2: { passed: false }, phase3: { passed: false } };
    try {
      var raw = localStorage.getItem(getProgressStorageKey(storageKey));
      return raw ? Object.assign(def, JSON.parse(raw) || {}) : def;
    } catch (e) { return def; }
  }

  var quizState = loadState();

  function saveState() {
    try { localStorage.setItem(getProgressStorageKey(storageKey), JSON.stringify(quizState)); } catch (e) {}
  }

  function isQuizUnlocked(key) {
    var dep = quizDependencies[key];
    return !dep || !!(quizState[dep] && quizState[dep].passed);
  }

  function clearDownstream(key) {
    var start = quizOrder.indexOf(key) + 1;
    quizOrder.slice(start).forEach(function (k) { quizState[k].passed = false; });
  }

  // ── Visited pages state ────────────────────────────────────────────────
  function loadVisited() {
    try {
      var raw = localStorage.getItem(getProgressStorageKey(visitedKey));
      return raw ? JSON.parse(raw) : {};
    } catch (e) { return {}; }
  }

  function saveVisited(visited) {
    try { localStorage.setItem(getProgressStorageKey(visitedKey), JSON.stringify(visited)); } catch (e) {}
  }

  function markPageVisited() {
    var file = getCurrentFileName();
    var skip = ["index.html", "resources.html", "glossary.html", ""];
    if (skip.indexOf(file) !== -1) return;
    var visited = loadVisited();
    if (!visited[file]) { visited[file] = true; saveVisited(visited); }
  }

  // ── 2. Active nav highlight + inject Resources / Glossary links ────────
  function setupNavHighlight() {
    var currentFile = getCurrentFileName();
    var phase = null;
    if (currentFile.indexOf("phase1") === 0) phase = "phase1";
    else if (currentFile.indexOf("phase2") === 0) phase = "phase2";
    else if (currentFile.indexOf("phase3") === 0) phase = "phase3";

    document.querySelectorAll(".nav-links a").forEach(function (link) {
      var href = link.getAttribute("href") || "";
      if ((currentFile === "index.html" || currentFile === "") && href === "index.html") {
        link.classList.add("active");
      } else if (phase && href.indexOf("#" + phase) !== -1) {
        link.classList.add("active");
      }
    });

    var navLinks = document.querySelector(".nav-links");
    if (navLinks) {
      var resLi = document.createElement("li");
      resLi.innerHTML = "<a href=\"resources.html\"" + (currentFile === "resources.html" ? " class=\"active\"" : "") + ">Resources</a>";
      navLinks.appendChild(resLi);
      var glossLi = document.createElement("li");
      glossLi.innerHTML = "<a href=\"glossary.html\"" + (currentFile === "glossary.html" ? " class=\"active\"" : "") + ">Glossary</a>";
      navLinks.appendChild(glossLi);
    }
  }

  // ── 5. Thin reading scroll-progress bar ───────────────────────────────
  function renderScrollBar() {
    var bar = document.createElement("div");
    bar.className = "reading-progress-bar";
    bar.setAttribute("role", "progressbar");
    bar.setAttribute("aria-label", "Reading progress");
    bar.setAttribute("aria-valuenow", "0");
    bar.setAttribute("aria-valuemin", "0");
    bar.setAttribute("aria-valuemax", "100");
    document.body.insertBefore(bar, document.body.firstChild);
    function update() {
      var st = window.scrollY || document.documentElement.scrollTop;
      var dh = document.documentElement.scrollHeight - window.innerHeight;
      var pct = dh > 0 ? Math.min(100, Math.round((st / dh) * 100)) : 0;
      bar.style.width = pct + "%";
      bar.setAttribute("aria-valuenow", pct);
    }
    window.addEventListener("scroll", update, { passive: true });
    update();
  }

  // ── 4. Back-to-top button ──────────────────────────────────────────────
  function renderBackToTop() {
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "back-to-top";
    btn.setAttribute("aria-label", "Back to top");
    btn.innerHTML = "&#8679;";
    document.body.appendChild(btn);
    window.addEventListener("scroll", function () {
      btn.classList.toggle("visible", window.scrollY > 300);
    }, { passive: true });
    btn.addEventListener("click", function () {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  // ── 3. Keyboard arrow-key navigation ──────────────────────────────────
  function setupKeyboardNav() {
    var currentFile = getCurrentFileName();
    var currentIndex = pageSequence.findIndex(function (p) { return p.file === currentFile; });
    if (currentIndex < 0) return;
    document.addEventListener("keydown", function (e) {
      var tag = (e.target || {}).tagName || "";
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "BUTTON" || tag === "SELECT") return;
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return;
      var prev = pageSequence[currentIndex - 1];
      var next = pageSequence[currentIndex + 1];
      if (e.key === "ArrowLeft" && prev) {
        window.location.href = prev.file;
      } else if (e.key === "ArrowRight" && next) {
        if (next.quizKey && !isQuizUnlocked(next.quizKey)) return;
        window.location.href = next.file;
      }
    });
  }

  // ── 1. Sidebar visited checkmarks ─────────────────────────────────────
  function markSidebarVisited() {
    var visited = loadVisited();
    document.querySelectorAll(".directory-link").forEach(function (link) {
      var href = link.getAttribute("href") || "";
      if (href && visited[href] && !link.classList.contains("current")) {
        if (!link.querySelector(".visited-check")) {
          var chk = document.createElement("span");
          chk.className = "visited-check";
          chk.textContent = "\u2713";
          chk.setAttribute("aria-label", "Visited");
          link.appendChild(chk);
        }
      }
    });
  }

  // ── 6. Sidebar overall progress widget ────────────────────────────────
  function renderSidebarProgress() {
    var sidebar = document.querySelector(".sidebar-card");
    if (!sidebar) return;
    var visited = loadVisited();
    var contentPages = pageSequence.filter(function (p) { return !p.quizKey; });
    var totalPages = contentPages.length;
    var visitedCount = contentPages.filter(function (p) { return visited[p.file]; }).length;
    var pct = totalPages > 0 ? Math.round((visitedCount / totalPages) * 100) : 0;
    var p1 = quizState.phase1.passed, p2 = quizState.phase2.passed, p3 = quizState.phase3.passed;
    var widget = document.createElement("div");
    widget.className = "sidebar-progress";
    widget.innerHTML =
      "<div class=\"sidebar-progress-label\">Overall Progress</div>"
      + "<div class=\"sidebar-progress-track\"><div class=\"sidebar-progress-fill\" style=\"width:" + pct + "%\"></div></div>"
      + "<div class=\"sidebar-progress-meta\">" + visitedCount + " of " + totalPages + " content pages read</div>"
      + "<div class=\"sidebar-quiz-status\">"
      + "<span class=\"sqstat" + (p1 ? " sqpass" : "") + "\">P1 " + (p1 ? "&#10003;" : "&mdash;") + "</span>"
      + "<span class=\"sqstat" + (p2 ? " sqpass" : "") + "\">P2 " + (p2 ? "&#10003;" : "&mdash;") + "</span>"
      + "<span class=\"sqstat" + (p3 ? " sqpass" : "") + "\">P3 " + (p3 ? "&#10003;" : "&mdash;") + "</span>"
      + "</div>";
    sidebar.insertBefore(widget, sidebar.firstChild);
  }

  function enhanceTopicGuide() {
    var pageDetail = document.querySelector(".page-detail");
    if (!pageDetail) return;

    var topicCard = null;
    var cards = pageDetail.querySelectorAll(".content-card");
    cards.forEach(function (card) {
      if (topicCard) return;
      var eyebrow = card.querySelector(".eyebrow");
      if (eyebrow && (eyebrow.textContent || "").trim().toLowerCase() === "topic guide") {
        topicCard = card;
      }
    });
    if (!topicCard) return;

    // Move Topic Guide to the top of the page detail content.
    if (pageDetail.firstElementChild !== topicCard) {
      pageDetail.insertBefore(topicCard, pageDetail.firstElementChild);
    }

    // Add one extra depth paragraph per topic page (once).
    if (topicCard.querySelector("[data-topic-guide-depth='true']")) return;

    var depthByPage = {
      "phase1-1.html": "A practical way to apply this topic is to classify candidate use cases into three buckets: automate, assist, and augment. If a use case needs strict determinism, keep AI in an assistive role with explicit human approval; if it needs speed and drafting support, use GenAI to generate first-pass outputs that business users review inside the process.",
      "phase1-2.html": "When comparing models, teams should run the same benchmark prompts across options and evaluate not only answer quality, but also latency, consistency, and cost at realistic token volumes. This creates a decision record that can be reused when models are upgraded or replaced.",
      "phase1-3.html": "Prompt quality improves fastest when teams maintain a small prompt library with version history, expected outputs, and failure examples. Treating prompts as testable assets helps reduce regressions when system instructions, model versions, or retrieval context changes.",
      "phase1-4.html": "Mature RAG implementations also define fallback behavior for low-confidence retrieval, such as asking a clarifying question or escalating to a human. This prevents confident but weakly grounded responses and improves trust in high-stakes workflows.",
      "phase1-5.html": "Architecture decisions become simpler when each product capability is mapped to a specific lifecycle stage: discover, design, build, run, and optimize. This avoids overloading one tool and creates clearer ownership for enablement, governance, and support.",
      "phase1-6.html": "An effective governance baseline includes risk classification, red-team testing cadence, approval checkpoints, and evidence retention. These controls should be proportional to impact, so low-risk assistants remain fast while high-impact workflows remain auditable and safe.",
      "phase2-1.html": "Operationally, teams should plan index refresh frequency and source ownership from day one. RAG quality often degrades because content freshness and metadata governance are treated as afterthoughts rather than first-class parts of the architecture.",
      "phase2-2.html": "In production, protocol choices should be paired with explicit authorization boundaries so agents can only invoke approved tools for their role. This combination of protocol standardization and least privilege is what makes multi-agent systems maintainable at scale.",
      "phase2-3.html": "A useful evaluation scorecard includes dimensions for platform fit, runtime controls, governance maturity, and developer ergonomics. Scoring each tool against weighted business priorities makes vendor selection more objective and easier to defend.",
      "phase2-4.html": "Teams usually get better outcomes by combining automated checks with periodic human audits on edge cases. This hybrid approach captures both measurable regressions and qualitative issues such as tone, policy adherence, and workflow appropriateness.",
      "phase2-5.html": "Observability should include user-centered measures like rework rate, escalation frequency, and time-to-resolution, not just technical metrics. These indicators reveal whether AI is genuinely improving business outcomes rather than only system performance.",
      "phase2-6.html": "Security reviews should validate the full execution chain: prompt input, retrieval context, model output, and downstream actions. Most serious incidents happen at boundaries between components, so end-to-end threat modeling is critical.",
      "phase3-1.html": "Reference architectures are most valuable when they are accompanied by implementation guardrails, such as approved integration patterns and reusable templates. This turns architecture from static documentation into an accelerator for delivery teams.",
      "phase3-2.html": "Portfolio depth pays off when solution teams define capability handoff points early, for example where Blueprint output becomes build-time assets and where runtime assistants consume governed knowledge sources. Clear handoffs reduce rework during scaling.",
      "phase3-3.html": "Integration strategy should be reviewed periodically as policy, model capabilities, and cost structures evolve. A design that starts cloud-first can transition to hybrid for sensitive workloads without major disruption if abstraction boundaries are respected.",
      "phase3-4.html": "Multi-agent orchestration should include explicit conflict-resolution rules for inconsistent agent outputs. Determining precedence, confidence thresholds, and human override paths prevents brittle behavior in real-world, ambiguous scenarios.",
      "phase3-5.html": "Connector reliability improves when teams standardize prompt contracts and output schemas, then validate them in pre-production with representative data. This reduces runtime parsing errors and makes downstream workflow behavior more predictable.",
      "phase3-6.html": "A strong CoE publishes reusable playbooks and starter artifacts, then measures adoption quality across teams. Governance is most effective when it enables delivery speed while maintaining evidence-based controls across the portfolio.",
      "phase3-7.html": "Before go-live, run a readiness drill that simulates incidents such as model outage, low-quality responses, and access-control failures. Rehearsing these scenarios validates runbooks, ownership, and communication paths under pressure."
    };

    var extra = depthByPage[currentFileName] || "As you continue, map each concept to a real workflow in your environment and define how you will measure outcome quality over time. This turns conceptual understanding into an operational plan that can be tested, improved, and governed.";
    var p = document.createElement("p");
    p.setAttribute("data-topic-guide-depth", "true");
    p.textContent = extra;
    topicCard.appendChild(p);
  }

  function renderUserSummary() {
    if (currentFileName !== "index.html" || !currentUser || !currentUser.profile) return;
    var container = document.querySelector(".page-main .container");
    if (!container) return;

    var visited = loadVisited();
    var contentPages = pageSequence.filter(function (p) { return !p.quizKey; });
    var totalPages = contentPages.length;
    var visitedCount = contentPages.filter(function (p) { return visited[p.file]; }).length;
    var pagePct = totalPages > 0 ? Math.round((visitedCount / totalPages) * 100) : 0;
    var passedCount = quizOrder.filter(function (key) { return quizState[key] && quizState[key].passed; }).length;
    var displayName = currentUser.profile.displayName || currentUser.key;

    var summary = document.createElement("div");
    summary.className = "content-card user-summary-card";
    summary.innerHTML = "<div class=\"eyebrow\">Signed In</div>"
      + "<h2>Welcome, " + displayName + "</h2>"
      + "<p>Your progress is saved under your account on this device.</p>"
      + "<div class=\"user-summary-grid mt1\">"
      + "<div><strong>Pages Read:</strong> " + visitedCount + " / " + totalPages + " (" + pagePct + "%)</div>"
      + "<div><strong>Quizzes Passed:</strong> " + passedCount + " / " + quizOrder.length + "</div>"
      + "</div>";

    var firstCard = container.querySelector(".content-card");
    if (firstCard) {
      container.insertBefore(summary, firstCard);
    } else {
      container.insertBefore(summary, container.firstChild);
    }
  }

  // ── 8. Mobile sidebar toggle ───────────────────────────────────────────
  function setupMobileSidebar() {
    var sidebar = document.querySelector(".sidebar-card");
    if (!sidebar) return;
    var toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "sidebar-toggle";
    toggle.innerHTML = "<span class=\"sidebar-toggle-icon\" aria-hidden=\"true\">&#9776;</span> Directory";
    toggle.setAttribute("aria-expanded", "true");
    toggle.addEventListener("click", function () {
      var collapsed = sidebar.classList.toggle("sidebar-collapsed");
      toggle.setAttribute("aria-expanded", String(!collapsed));
    });
    var progress = sidebar.querySelector(".sidebar-progress");
    if (progress && progress.nextSibling) {
      sidebar.insertBefore(toggle, progress.nextSibling);
    } else {
      sidebar.insertBefore(toggle, sidebar.firstChild);
    }
  }

  // ── Quiz link locking ──────────────────────────────────────────────────
  function refreshQuizLinks() {
    document.querySelectorAll("[data-quiz-link]").forEach(function (link) {
      var key = link.getAttribute("data-quiz-link");
      var unlocked = isQuizUnlocked(key);
      link.classList.toggle("locked-link", !unlocked);
      if (!unlocked) {
        link.setAttribute("aria-disabled", "true");
        link.title = "Pass the previous phase quiz to unlock this quiz.";
      } else {
        link.removeAttribute("aria-disabled");
        link.removeAttribute("title");
      }
    });
  }

  // ── Render prev/next trail ─────────────────────────────────────────────
  function renderNextTrail() {
    var currentFile = getCurrentFileName();
    var currentIndex = pageSequence.findIndex(function (page) { return page.file === currentFile; });
    var currentPage = currentIndex >= 0 ? pageSequence[currentIndex] : null;
    var prevPage = currentPage ? pageSequence[currentIndex - 1] : null;
    var nextPage = currentPage ? pageSequence[currentIndex + 1] : pageSequence[0];
    var currentLabel = currentPage ? currentPage.label : "Overview";

    var existing = document.querySelector("[data-next-trail]");
    if (existing) existing.remove();

    var container = document.querySelector(".page-main .container");
    if (!container) return;

    var trail = document.createElement("div");
    trail.className = "next-trail";
    trail.setAttribute("data-next-trail", "true");

    var prevActionHtml = prevPage
      ? "<a class=\"btn btn-outline next-trail-link\" href=\"" + prevPage.file + "\"" + (prevPage.quizKey ? " data-quiz-link=\"" + prevPage.quizKey + "\"" : "") + ">&larr; " + prevPage.label + "</a>"
      : "";
    var nextActionHtml = nextPage
      ? "<a class=\"btn btn-primary next-trail-link\" href=\"" + nextPage.file + "\"" + (nextPage.quizKey ? " data-quiz-link=\"" + nextPage.quizKey + "\"" : "") + ">" + nextPage.label + " &rarr;</a>"
      : "<a class=\"btn btn-primary next-trail-link\" href=\"index.html\">Back to Overview</a>";
    var actionsHtml = "<div class=\"next-trail-actions\">" + prevActionHtml + nextActionHtml + "</div>";
    var kbHint = currentPage ? "<div class=\"next-trail-kb\">&#9664; &#9654; arrow keys also navigate</div>" : "";

    var bodyHtml = currentPage
      ? "<div><div class=\"next-trail-title\">You are here: " + currentLabel + "</div><div class=\"next-trail-copy\">" + (nextPage ? "Move backward or continue forward through the curriculum." : "You have reached the end of the learning path.") + kbHint + "</div></div>" + actionsHtml
      : "<div><div class=\"next-trail-title\">Start the learning path</div><div class=\"next-trail-copy\">Jump directly into the first subsection and move page by page through the curriculum.</div></div>" + actionsHtml;

    trail.innerHTML = bodyHtml;

    var reference = currentFile === "index.html"
      ? document.querySelector(".content-card")
      : document.querySelector(".page-breadcrumb");
    if (reference && reference.parentNode) {
      reference.parentNode.insertBefore(trail, reference.nextSibling);
    } else {
      container.insertBefore(trail, container.firstChild);
    }
  }

  // ── Sticky sequence progress indicator ────────────────────────────────
  function renderSequenceProgress() {
    var currentFile = getCurrentFileName();
    var currentIndex = pageSequence.findIndex(function (page) { return page.file === currentFile; });
    var total = pageSequence.length;
    var completed = currentIndex >= 0 ? (currentIndex + 1) : 0;
    var percent = total ? Math.round((completed / total) * 100) : 0;
    var currentLabel = currentIndex >= 0 ? pageSequence[currentIndex].label : "Overview";

    var existing = document.querySelector("[data-page-sequence-progress]");
    if (existing) existing.remove();

    var nav = document.querySelector("nav");
    if (!nav || !nav.parentNode) return;

    var shell = document.createElement("div");
    shell.className = "page-sequence-progress";
    shell.setAttribute("data-page-sequence-progress", "true");
    shell.innerHTML = "<div class=\"container\">"
      + "<div class=\"page-sequence-copy\">"
      + "<div class=\"page-sequence-kicker\">Learning Progress</div>"
      + "<div class=\"page-sequence-label\">" + currentLabel + "</div>"
      + "</div>"
      + "<div class=\"page-sequence-bar\" aria-label=\"Learning path progress\">"
      + "<div class=\"page-sequence-bar-fill\" style=\"width: " + percent + "%;\"></div>"
      + "</div>"
      + "<div class=\"page-sequence-meta\">" + completed + " of " + total + " pages</div>"
      + "</div>";
    nav.parentNode.insertBefore(shell, nav.nextSibling);
  }

  // ── 9. Quiz setup with randomization ──────────────────────────────────
  function setupQuiz(panel) {
    var key = panel.getAttribute("data-quiz");
    var allQuestions = quizData[key] || [];
    if (!allQuestions.length) return;

    var questions = shuffleArray(allQuestions).slice(0, QUIZ_PER_SET);

    var questionEl  = panel.querySelector("[data-quiz-question]");
    var optionsEl   = panel.querySelector("[data-quiz-options]");
    var progressEl  = panel.querySelector("[data-quiz-progress]");
    var nextEl      = panel.querySelector("[data-quiz-next]");
    var resultsEl   = panel.querySelector("[data-quiz-results]");
    var lockEl      = panel.querySelector("[data-quiz-lock]");
    var current = 0;
    var answers = [];

    function refreshLockState() {
      var unlocked = isQuizUnlocked(key);
      panel.classList.toggle("locked", !unlocked);
      if (!unlocked) {
        var dep = quizDependencies[key];
        if (lockEl && dep) {
          lockEl.textContent = "Locked until you pass the " + dep.replace("phase", "Phase ") + " quiz with 75% or higher.";
        }
        if (progressEl) progressEl.textContent = "Locked";
      }
      refreshQuizLinks();
      return unlocked;
    }

    function renderQuestion() {
      if (!refreshLockState()) return;
      var q = questions[current];
      progressEl.textContent = "Question " + (current + 1) + " of " + questions.length;
      questionEl.textContent = q.question;
      optionsEl.innerHTML = "";
      resultsEl.hidden = true;
      nextEl.textContent = current === questions.length - 1 ? "Finish Quiz" : "Next Question";
      nextEl.disabled = answers[current] === undefined;
      q.options.forEach(function (option, idx) {
        var btn = document.createElement("button");
        btn.type = "button";
        btn.className = "quiz-option" + (answers[current] === idx ? " selected" : "");
        btn.textContent = String.fromCharCode(65 + idx) + ". " + option;
        btn.addEventListener("click", function () {
          answers[current] = idx;
          nextEl.disabled = false;
          Array.prototype.forEach.call(optionsEl.querySelectorAll(".quiz-option"), function (el) { el.classList.remove("selected"); });
          btn.classList.add("selected");
        });
        optionsEl.appendChild(btn);
      });
    }

    function renderResults() {
      if (!refreshLockState()) return;
      var correctCount = 0;
      var items = "";
      questions.forEach(function (q, idx) {
        var chosen = answers[idx];
        var isCorrect = chosen === q.correct;
        if (isCorrect) correctCount += 1;
        var chosenLabel = chosen === undefined ? "No answer" : String.fromCharCode(65 + chosen) + ". " + q.options[chosen];
        var correctLabel = String.fromCharCode(65 + q.correct) + ". " + q.options[q.correct];
        var whyText = isCorrect ? ("Correct. " + q.why) : ("Incorrect \u2014 right answer: " + correctLabel + ". " + q.why);
        items += "<li class=\"quiz-result-item " + (isCorrect ? "ok" : "bad") + "\">"
          + "<div class=\"quiz-result-q\">Q" + (idx + 1) + ": " + q.question + "</div>"
          + "<div class=\"quiz-result-meta\">Your answer: " + chosenLabel + "</div>"
          + "<div class=\"quiz-result-why\">" + whyText + "</div>"
          + "</li>";
      });

      var scorePercent = Math.round((correctCount / questions.length) * 100);
      var passed = scorePercent >= 75;
      quizState[key].passed = passed;
      if (!passed) clearDownstream(key);
      saveState();
      refreshQuizLinks();

      var nextIndex = quizOrder.indexOf(key) + 1;
      var nextKey = quizOrder[nextIndex];
      var status = passed ? "PASS \u2713" : "REVIEW";
      var unlockHtml = "";
      if (passed && nextKey) {
        unlockHtml = "<div class=\"callout\"><span class=\"ci\">&#128275;</span><div>You passed. The " + nextKey.replace("phase", "Phase ") + " quiz is now unlocked. Retaking draws a new random set of questions.</div></div>";
      } else if (!passed) {
        unlockHtml = "<div class=\"callout\"><span class=\"ci\">&#8635;</span><div>You need 75%+ to unlock the next quiz. Retaking draws a fresh random set of questions.</div></div>";
      }

      resultsEl.innerHTML = "<div class=\"quiz-score\">Score: " + correctCount + "/" + questions.length + " (" + scorePercent + "%) &mdash; " + status + "</div>"
        + unlockHtml
        + "<ul class=\"quiz-result-list\">" + items + "</ul>"
        + "<button type=\"button\" class=\"btn btn-outline quiz-restart\" data-quiz-restart>Retake Quiz (new questions)</button>";
      resultsEl.hidden = false;

      var restartBtn = resultsEl.querySelector("[data-quiz-restart]");
      if (restartBtn) {
        restartBtn.addEventListener("click", function () {
          questions = shuffleArray(allQuestions).slice(0, QUIZ_PER_SET);
          current = 0;
          answers = [];
          renderQuestion();
        });
      }
    }

    nextEl.addEventListener("click", function () {
      if (!refreshLockState() || answers[current] === undefined) return;
      if (current === questions.length - 1) { renderResults(); return; }
      current += 1;
      renderQuestion();
    });

    renderQuestion();
  }

  // ── Init (order matters) ───────────────────────────────────────────────
  markPageVisited();
  setupNavHighlight();
  setupAccountControls();
  renderUserSummary();
  enhanceTopicGuide();
  renderScrollBar();
  renderBackToTop();
  renderSequenceProgress();
  renderNextTrail();
  refreshQuizLinks();
  markSidebarVisited();
  renderSidebarProgress();
  setupMobileSidebar();
  setupKeyboardNav();

  document.addEventListener("click", function (event) {
    var link = event.target.closest("[data-quiz-link]");
    if (link && link.classList.contains("locked-link")) event.preventDefault();
  });

  document.querySelectorAll(".quiz-panel[data-quiz]").forEach(setupQuiz);
})();


