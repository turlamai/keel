# keel

[English](README.md) · **中文**

`keel` 是 Racket 桌面运行时共享的传输中立应用契约。它为原生渲染与 WebView 渲染的技术栈提供同一个小型值模型、同一种规范字节编码、同一种结构化错误形态、同一套生命周期词汇、同一套传输中立的 schema 词汇，以及同一个兼容性语料库。

本包刻意**不**负责 UI 控件、传输帧、进程嵌入、HTTP、WebView 消息或平台策略。Rivet 保留 RVT1 及其 WinUI 3 / SwiftUI-AppKit / GTK4 宿主；Glaze 保留 GLZ1 及其原生 WebView 适配器。

Permit 与 Commerce 被刻意排除在这条依赖链之外。产品可以在 Rivet 或 Glaze 旁边组合 Permit 以获得签名商业授权，并在需要在线销售编排时加入 Commerce。Permit 不依赖 Keel 或任一框架；Commerce 的无头核心不使用 Keel。权威的五仓库依赖图、所有权规则与发布顺序见[家族架构](docs/family-architecture.md)。

## 使用入口

Keel 适用于运行时共享的传输中立值、规范字节、schema 与结构化错误。大多数产品开发者应从 Rivet 或 Glaze 入手，而不是围绕 Keel 再组装一个应用框架。

[使用选择、成熟度、升级与支持](docs/USING.zh-CN.md) · [English](docs/USING.md)

## 契约 v1

值的联合类型为：

- Null、Bool、有符号 Int64、有限 Float64、UTF-8 String、Bytes
- List 与以 String 为键的不可变 Map
- 结构化 Error：kebab-case 的 code、面向人的 message、可选的 data 值

编码是规范的。既有 RVT1 标量/列表标签保持字节一致；Float64、Map 与 Error 追加新标签。Map 键按其 UTF-8 字节排序，非有限浮点数会被拒绝，解码时拒绝重复/非规范键，且每个实现都强制执行相同的 64 MiB、深度 64 与 262,144 节点预算。见[规范性契约](docs/contract-v1.md)。

```racket
#lang racket/base

(require keel)

(define payload
  (hash "task" "review"
        "progress" 0.5
        "tags" (list "racket" "desktop")))

(define wire (encode-app-value payload))
(decode-app-value wire)

(make-app-error "invalid-args" "Expected a non-empty title"
                (hash "field" "title"))
```

Schema 描述应用边界，而不规定其传输方式：

```racket
(define Task
  (schema-record 'Task
                 (list (schema-field 'id Int64)
                       (schema-field 'title String))))

(define task-schema
  (make-app-schema
   "org.racket.taskboard" 1
   #:records (list Task)
   #:commands
   (list (schema-command 'create-task
                         (list (schema-parameter 'title String))
                         (reference-type 'Task)
                         '("invalid-args")))))

(encode-app-schema task-schema)
```

Rivet 可以把一条命令映射为 RVT1 RPC，而 Glaze 将其映射为 GLZ1 invoke；schema 不拥有其中任何一种信封。Schema 名称保留普通 Racket 约定，如 `ready?`、`save!` 和 `string->bytes`，并支持 Unicode；经冲突检查的源语言标识符由消费端代码生成器负责。

## 兼容性纪律

`tests/golden-v1.txt` 是规范性字节语料库。修改既有任何一行都构成兼容性破坏。新增联合成员需要书面理由、新的跨运行时 golden 向量、解码器预算测试，以及一次版本决策。传输协议可以嵌入此编解码器，但必须自行协商各自的版本与错误分类法。

## 官方包目录安装状态

**2026-10-29 官方包目录已经修复**：
[Keel 官方记录](https://pkgs.racket-lang.org/package/keel)
现指向 `https://github.com/turlamai/keel.git#main`，Racket 9.3
官方构建与 **2,361 项测试均通过**。
[包目录验收门禁](docs/package-catalog-release.md)继续防止再次失效；
[Issue #8](https://github.com/turlamai/keel/issues/8)
尚须记录 Rivet/Glaze 下游环境复验结果，而不是要求再次修改包目录。

## 开发

```sh
raco pkg install --auto --name keel --link
raco test -p keel
```

本包支持 Racket 9.0 及更新版本，采用 MIT 许可证。

兼容性变更遵循 [CONTRIBUTING.md](CONTRIBUTING.md) 中的评审门禁。疑似安全漏洞请通过 [SECURITY.md](SECURITY.md) 中的私密流程报告。
