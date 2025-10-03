// NetLang - Network Algorithm Language Implementation
// Lexer, Parser, and Interpreter for graph algorithm visualization

// ============================================================================
// LEXER
// ============================================================================

export enum TokenType {
    // Literals
    NUMBER = 'NUMBER',
    STRING = 'STRING',
    TRUE = 'TRUE',
    FALSE = 'FALSE',
    NULL = 'NULL',

    // Identifiers and keywords
    IDENTIFIER = 'IDENTIFIER',
    LET = 'LET',
    IF = 'IF',
    ELSE = 'ELSE',
    WHILE = 'WHILE',
    FOR = 'FOR',
    IN = 'IN',
    FUNCTION = 'FUNCTION',
    RETURN = 'RETURN',
    BREAK = 'BREAK',
    CONTINUE = 'CONTINUE',

    // Operators
    PLUS = 'PLUS',
    MINUS = 'MINUS',
    STAR = 'STAR',
    SLASH = 'SLASH',
    PERCENT = 'PERCENT',
    EQ = 'EQ',
    NEQ = 'NEQ',
    LT = 'LT',
    GT = 'GT',
    LTE = 'LTE',
    GTE = 'GTE',
    AND = 'AND',
    OR = 'OR',
    NOT = 'NOT',
    ASSIGN = 'ASSIGN',

    // Punctuation
    LPAREN = 'LPAREN',
    RPAREN = 'RPAREN',
    LBRACE = 'LBRACE',
    RBRACE = 'RBRACE',
    LBRACKET = 'LBRACKET',
    RBRACKET = 'RBRACKET',
    COMMA = 'COMMA',
    DOT = 'DOT',
    COLON = 'COLON',

    // Special
    NEWLINE = 'NEWLINE',
    EOF = 'EOF'
}

export class Token {
    constructor(
        public type: TokenType,
        public value: any,
        public line: number,
        public col: number
    ) {}
}

export class Lexer {
    private pos: number = 0;
    private line: number = 1;
    private col: number = 1;
    private tokens: Token[] = [];

    constructor(private source: string) {}

    private peek(offset: number = 0): string | null {
        const pos = this.pos + offset;
        return pos < this.source.length ? this.source[pos] : null;
    }

    private advance(): string {
        const ch = this.source[this.pos++];
        if (ch === '\n') {
            this.line++;
            this.col = 1;
        } else {
            this.col++;
        }
        return ch;
    }

    private skipWhitespace(): void {
        while (this.peek() && /[ \t\r]/.test(this.peek()!)) {
            this.advance();
        }
    }

    private skipComment(): void {
        if (this.peek() === '/' && this.peek(1) === '/') {
            while (this.peek() && this.peek() !== '\n') {
                this.advance();
            }
        }
    }

    private readNumber(): Token {
        const startLine = this.line;
        const startCol = this.col;
        let num = '';

        while (this.peek() && /[0-9.]/.test(this.peek()!)) {
            num += this.advance();
        }

        return new Token(TokenType.NUMBER, parseFloat(num), startLine, startCol);
    }

    private readString(): Token {
        const startLine = this.line;
        const startCol = this.col;
        this.advance(); // skip opening quote
        let str = '';

        while (this.peek() && this.peek() !== '"') {
            if (this.peek() === '\\') {
                this.advance();
                const next = this.advance();
                switch (next) {
                    case 'n': str += '\n'; break;
                    case 't': str += '\t'; break;
                    case '\\': str += '\\'; break;
                    case '"': str += '"'; break;
                    default: str += next;
                }
            } else {
                str += this.advance();
            }
        }

        this.advance(); // skip closing quote
        return new Token(TokenType.STRING, str, startLine, startCol);
    }

    private readIdentifier(): Token {
        const startLine = this.line;
        const startCol = this.col;
        let ident = '';

        while (this.peek() && /[a-zA-Z0-9_]/.test(this.peek()!)) {
            ident += this.advance();
        }

        // Check for keywords
        const keywords: Record<string, TokenType> = {
            'let': TokenType.LET,
            'if': TokenType.IF,
            'else': TokenType.ELSE,
            'while': TokenType.WHILE,
            'for': TokenType.FOR,
            'in': TokenType.IN,
            'function': TokenType.FUNCTION,
            'return': TokenType.RETURN,
            'break': TokenType.BREAK,
            'continue': TokenType.CONTINUE,
            'true': TokenType.TRUE,
            'false': TokenType.FALSE,
            'null': TokenType.NULL,
            'and': TokenType.AND,
            'or': TokenType.OR,
            'not': TokenType.NOT
        };

        const type = keywords[ident] || TokenType.IDENTIFIER;
        const value = type === TokenType.IDENTIFIER ? ident :
                     type === TokenType.TRUE ? true :
                     type === TokenType.FALSE ? false :
                     type === TokenType.NULL ? null : ident;

        return new Token(type, value, startLine, startCol);
    }

    tokenize(): Token[] {
        while (this.pos < this.source.length) {
            this.skipWhitespace();
            this.skipComment();

            if (this.pos >= this.source.length) break;

            const ch = this.peek();
            const line = this.line;
            const col = this.col;

            if (!ch) break;

            // Newlines
            if (ch === '\n') {
                this.advance();
                continue;
            }

            // Numbers
            if (/[0-9]/.test(ch)) {
                this.tokens.push(this.readNumber());
                continue;
            }

            // Strings
            if (ch === '"') {
                this.tokens.push(this.readString());
                continue;
            }

            // Identifiers
            if (/[a-zA-Z_]/.test(ch)) {
                this.tokens.push(this.readIdentifier());
                continue;
            }

            // Two-character operators
            if (ch === '=' && this.peek(1) === '=') {
                this.advance();
                this.advance();
                this.tokens.push(new Token(TokenType.EQ, '==', line, col));
                continue;
            }

            if (ch === '!' && this.peek(1) === '=') {
                this.advance();
                this.advance();
                this.tokens.push(new Token(TokenType.NEQ, '!=', line, col));
                continue;
            }

            if (ch === '<' && this.peek(1) === '=') {
                this.advance();
                this.advance();
                this.tokens.push(new Token(TokenType.LTE, '<=', line, col));
                continue;
            }

            if (ch === '>' && this.peek(1) === '=') {
                this.advance();
                this.advance();
                this.tokens.push(new Token(TokenType.GTE, '>=', line, col));
                continue;
            }

            // Single-character tokens
            const singleChar: Record<string, TokenType> = {
                '+': TokenType.PLUS,
                '-': TokenType.MINUS,
                '*': TokenType.STAR,
                '/': TokenType.SLASH,
                '%': TokenType.PERCENT,
                '<': TokenType.LT,
                '>': TokenType.GT,
                '=': TokenType.ASSIGN,
                '(': TokenType.LPAREN,
                ')': TokenType.RPAREN,
                '{': TokenType.LBRACE,
                '}': TokenType.RBRACE,
                '[': TokenType.LBRACKET,
                ']': TokenType.RBRACKET,
                ',': TokenType.COMMA,
                '.': TokenType.DOT,
                ':': TokenType.COLON
            };

            if (singleChar[ch]) {
                this.advance();
                this.tokens.push(new Token(singleChar[ch], ch, line, col));
                continue;
            }

            throw new Error(`Unexpected character '${ch}' at line ${line}, col ${col}`);
        }

        this.tokens.push(new Token(TokenType.EOF, null, this.line, this.col));
        return this.tokens;
    }
}

// ============================================================================
// PARSER
// ============================================================================

export interface ASTNode {
    type: string;
}

export interface Program extends ASTNode {
    type: 'Program';
    statements: Statement[];
}

export interface LetStatement extends ASTNode {
    type: 'LetStatement';
    name: string;
    value: Expression;
}

export interface AssignStatement extends ASTNode {
    type: 'AssignStatement';
    name: string;
    value: Expression;
}

export interface IfStatement extends ASTNode {
    type: 'IfStatement';
    condition: Expression;
    thenBlock: Statement[];
    elseBlock: Statement[] | null;
}

export interface WhileStatement extends ASTNode {
    type: 'WhileStatement';
    condition: Expression;
    body: Statement[];
}

export interface ForStatement extends ASTNode {
    type: 'ForStatement';
    variable: string;
    iterable: Expression;
    body: Statement[];
}

export interface FunctionDecl extends ASTNode {
    type: 'FunctionDecl';
    name: string;
    params: string[];
    body: Statement[];
}

export interface ReturnStatement extends ASTNode {
    type: 'ReturnStatement';
    value: Expression | null;
}

export interface BreakStatement extends ASTNode {
    type: 'BreakStatement';
}

export interface ContinueStatement extends ASTNode {
    type: 'ContinueStatement';
}

export interface ExpressionStatement extends ASTNode {
    type: 'ExpressionStatement';
    expression: Expression;
}

export type Statement = LetStatement | AssignStatement | IfStatement | WhileStatement |
                        ForStatement | FunctionDecl | ReturnStatement | BreakStatement |
                        ContinueStatement | ExpressionStatement;

export interface BinaryOp extends ASTNode {
    type: 'BinaryOp';
    operator: string;
    left: Expression;
    right: Expression;
}

export interface UnaryOp extends ASTNode {
    type: 'UnaryOp';
    operator: string;
    operand: Expression;
}

export interface CallExpression extends ASTNode {
    type: 'CallExpression';
    name: string;
    args: Expression[];
}

export interface MemberExpression extends ASTNode {
    type: 'MemberExpression';
    object: Expression;
    property: string;
}

export interface IndexExpression extends ASTNode {
    type: 'IndexExpression';
    object: Expression;
    index: Expression;
}

export interface Identifier extends ASTNode {
    type: 'Identifier';
    name: string;
}

export interface Literal extends ASTNode {
    type: 'Literal';
    value: any;
}

export interface ArrayLiteral extends ASTNode {
    type: 'ArrayLiteral';
    elements: Expression[];
}

export interface SetLiteral extends ASTNode {
    type: 'SetLiteral';
    elements: Expression[];
}

export interface MapLiteral extends ASTNode {
    type: 'MapLiteral';
    pairs: Array<{key: string; value: Expression}>;
}

export type Expression = BinaryOp | UnaryOp | CallExpression | MemberExpression |
                         IndexExpression | Identifier | Literal | ArrayLiteral |
                         SetLiteral | MapLiteral;

export class Parser {
    private pos: number = 0;

    constructor(private tokens: Token[]) {}

    private peek(offset: number = 0): Token {
        const pos = this.pos + offset;
        return pos < this.tokens.length ? this.tokens[pos] : this.tokens[this.tokens.length - 1];
    }

    private advance(): Token {
        return this.tokens[this.pos++];
    }

    private expect(type: TokenType): Token {
        const token = this.peek();
        if (token.type !== type) {
            throw new Error(`Expected ${type} but got ${token.type} at line ${token.line}`);
        }
        return this.advance();
    }

    private match(...types: TokenType[]): boolean {
        return types.includes(this.peek().type);
    }

    parse(): Program {
        const statements: Statement[] = [];
        while (!this.match(TokenType.EOF)) {
            statements.push(this.parseStatement());
        }
        return { type: 'Program', statements };
    }

    private parseStatement(): Statement {
        if (this.match(TokenType.LET)) return this.parseLetStatement();
        if (this.match(TokenType.IF)) return this.parseIfStatement();
        if (this.match(TokenType.WHILE)) return this.parseWhileStatement();
        if (this.match(TokenType.FOR)) return this.parseForStatement();
        if (this.match(TokenType.FUNCTION)) return this.parseFunctionDecl();
        if (this.match(TokenType.RETURN)) return this.parseReturnStatement();
        if (this.match(TokenType.BREAK)) {
            this.advance();
            return { type: 'BreakStatement' };
        }
        if (this.match(TokenType.CONTINUE)) {
            this.advance();
            return { type: 'ContinueStatement' };
        }

        // Check for assignment
        if (this.match(TokenType.IDENTIFIER) && this.peek(1).type === TokenType.ASSIGN) {
            const name = this.advance().value as string;
            this.expect(TokenType.ASSIGN);
            const value = this.parseExpression();
            return { type: 'AssignStatement', name, value };
        }

        return { type: 'ExpressionStatement', expression: this.parseExpression() };
    }

    private parseLetStatement(): LetStatement {
        this.expect(TokenType.LET);
        const name = this.expect(TokenType.IDENTIFIER).value as string;
        this.expect(TokenType.ASSIGN);
        const value = this.parseExpression();
        return { type: 'LetStatement', name, value };
    }

    private parseIfStatement(): IfStatement {
        this.expect(TokenType.IF);
        const condition = this.parseExpression();
        const thenBlock = this.parseBlock();
        let elseBlock: Statement[] | null = null;

        if (this.match(TokenType.ELSE)) {
            this.advance();
            if (this.match(TokenType.IF)) {
                elseBlock = [this.parseIfStatement()];
            } else {
                elseBlock = this.parseBlock();
            }
        }

        return { type: 'IfStatement', condition, thenBlock, elseBlock };
    }

    private parseWhileStatement(): WhileStatement {
        this.expect(TokenType.WHILE);
        const condition = this.parseExpression();
        const body = this.parseBlock();
        return { type: 'WhileStatement', condition, body };
    }

    private parseForStatement(): ForStatement {
        this.expect(TokenType.FOR);
        const variable = this.expect(TokenType.IDENTIFIER).value as string;
        this.expect(TokenType.IN);
        const iterable = this.parseExpression();
        const body = this.parseBlock();
        return { type: 'ForStatement', variable, iterable, body };
    }

    private parseFunctionDecl(): FunctionDecl {
        this.expect(TokenType.FUNCTION);
        const name = this.expect(TokenType.IDENTIFIER).value as string;
        this.expect(TokenType.LPAREN);

        const params: string[] = [];
        while (!this.match(TokenType.RPAREN)) {
            params.push(this.expect(TokenType.IDENTIFIER).value as string);
            if (this.match(TokenType.COMMA)) this.advance();
        }

        this.expect(TokenType.RPAREN);
        const body = this.parseBlock();
        return { type: 'FunctionDecl', name, params, body };
    }

    private parseReturnStatement(): ReturnStatement {
        this.expect(TokenType.RETURN);
        const value = this.match(TokenType.RBRACE, TokenType.EOF) ? null : this.parseExpression();
        return { type: 'ReturnStatement', value };
    }

    private parseBlock(): Statement[] {
        this.expect(TokenType.LBRACE);
        const statements: Statement[] = [];
        while (!this.match(TokenType.RBRACE)) {
            statements.push(this.parseStatement());
        }
        this.expect(TokenType.RBRACE);
        return statements;
    }

    private parseExpression(): Expression {
        return this.parseLogicalOr();
    }

    private parseLogicalOr(): Expression {
        let left = this.parseLogicalAnd();
        while (this.match(TokenType.OR)) {
            const op = this.advance().value as string;
            const right = this.parseLogicalAnd();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseLogicalAnd(): Expression {
        let left = this.parseEquality();
        while (this.match(TokenType.AND)) {
            const op = this.advance().value as string;
            const right = this.parseEquality();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseEquality(): Expression {
        let left = this.parseComparison();
        while (this.match(TokenType.EQ, TokenType.NEQ)) {
            const op = this.advance().value as string;
            const right = this.parseComparison();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseComparison(): Expression {
        let left = this.parseTerm();
        while (this.match(TokenType.LT, TokenType.GT, TokenType.LTE, TokenType.GTE)) {
            const op = this.advance().value as string;
            const right = this.parseTerm();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseTerm(): Expression {
        let left = this.parseFactor();
        while (this.match(TokenType.PLUS, TokenType.MINUS)) {
            const op = this.advance().value as string;
            const right = this.parseFactor();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseFactor(): Expression {
        let left = this.parseUnary();
        while (this.match(TokenType.STAR, TokenType.SLASH, TokenType.PERCENT)) {
            const op = this.advance().value as string;
            const right = this.parseUnary();
            left = { type: 'BinaryOp', operator: op, left, right };
        }
        return left;
    }

    private parseUnary(): Expression {
        if (this.match(TokenType.NOT, TokenType.MINUS)) {
            const op = this.advance().value as string;
            const operand = this.parseUnary();
            return { type: 'UnaryOp', operator: op, operand };
        }
        return this.parsePostfix();
    }

    private parsePostfix(): Expression {
        let expr = this.parsePrimary();

        while (true) {
            if (this.match(TokenType.LPAREN)) {
                // Function call
                this.advance();
                const args: Expression[] = [];
                while (!this.match(TokenType.RPAREN)) {
                    args.push(this.parseExpression());
                    if (this.match(TokenType.COMMA)) this.advance();
                }
                this.expect(TokenType.RPAREN);
                if (expr.type !== 'Identifier') {
                    throw new Error('Can only call identifiers');
                }
                expr = { type: 'CallExpression', name: expr.name, args };
            } else if (this.match(TokenType.DOT)) {
                // Member access
                this.advance();
                const property = this.expect(TokenType.IDENTIFIER).value as string;
                expr = { type: 'MemberExpression', object: expr, property };
            } else if (this.match(TokenType.LBRACKET)) {
                // Index access
                this.advance();
                const index = this.parseExpression();
                this.expect(TokenType.RBRACKET);
                expr = { type: 'IndexExpression', object: expr, index };
            } else {
                break;
            }
        }

        return expr;
    }

    private parsePrimary(): Expression {
        if (this.match(TokenType.NUMBER, TokenType.STRING, TokenType.TRUE, TokenType.FALSE, TokenType.NULL)) {
            return { type: 'Literal', value: this.advance().value };
        }

        if (this.match(TokenType.IDENTIFIER)) {
            return { type: 'Identifier', name: this.advance().value as string };
        }

        if (this.match(TokenType.LPAREN)) {
            this.advance();
            const expr = this.parseExpression();
            this.expect(TokenType.RPAREN);
            return expr;
        }

        if (this.match(TokenType.LBRACKET)) {
            return this.parseArrayLiteral();
        }

        if (this.match(TokenType.LBRACE)) {
            // Could be set or map
            if (this.peek(1).type === TokenType.RBRACE) {
                // Empty {} - treat as map
                this.advance();
                this.advance();
                return { type: 'MapLiteral', pairs: [] };
            }

            // Look ahead to determine if it's a map
            let isMap = false;
            let lookahead = 1;
            while (this.peek(lookahead).type !== TokenType.RBRACE && this.peek(lookahead).type !== TokenType.EOF) {
                if (this.peek(lookahead).type === TokenType.COLON) {
                    isMap = true;
                    break;
                }
                lookahead++;
            }

            return isMap ? this.parseMapLiteral() : this.parseSetLiteral();
        }

        throw new Error(`Unexpected token ${this.peek().type} at line ${this.peek().line}`);
    }

    private parseArrayLiteral(): ArrayLiteral {
        this.expect(TokenType.LBRACKET);
        const elements: Expression[] = [];
        while (!this.match(TokenType.RBRACKET)) {
            elements.push(this.parseExpression());
            if (this.match(TokenType.COMMA)) this.advance();
        }
        this.expect(TokenType.RBRACKET);
        return { type: 'ArrayLiteral', elements };
    }

    private parseSetLiteral(): SetLiteral {
        this.expect(TokenType.LBRACE);
        const elements: Expression[] = [];
        while (!this.match(TokenType.RBRACE)) {
            elements.push(this.parseExpression());
            if (this.match(TokenType.COMMA)) this.advance();
        }
        this.expect(TokenType.RBRACE);
        return { type: 'SetLiteral', elements };
    }

    private parseMapLiteral(): MapLiteral {
        this.expect(TokenType.LBRACE);
        const pairs: Array<{key: string; value: Expression}> = [];
        while (!this.match(TokenType.RBRACE)) {
            const key = this.expect(TokenType.IDENTIFIER).value as string;
            this.expect(TokenType.COLON);
            const value = this.parseExpression();
            pairs.push({ key, value });
            if (this.match(TokenType.COMMA)) this.advance();
        }
        this.expect(TokenType.RBRACE);
        return { type: 'MapLiteral', pairs };
    }
}

// ============================================================================
// INTERPRETER
// ============================================================================

export interface NetLangQueue {
    type: 'queue';
    items: any[];
}

export interface NetLangSet {
    type: 'set';
    items: Set<any>;
}

export interface NetLangMap {
    type: 'map';
    items: Map<any, any>;
}

export interface NetLangPriorityQueue {
    type: 'pq';
    heap: any[];
}

export type NetLangCollection = NetLangQueue | NetLangSet | NetLangMap | NetLangPriorityQueue;

export interface GraphAPI {
    nodes(): number[];
    neighbors(id: number): number[];
    edges(): Array<{from: number; to: number; weight: number}>;
    weight(from: number, to: number): number | null;
    nodeCount(): number;
    highlightNode(id: number, color: string): void;
    highlightEdge(from: number, to: number, color: string): void;
    setNodeLabel(id: number, text: string): void;
    setEdgeLabel(from: number, to: number, text: string): void;
    log(message: string): void;
    sleep(ms: number): Promise<void>;
}

class Environment {
    private vars: Map<string, any> = new Map();

    constructor(private parent: Environment | null = null) {}

    define(name: string, value: any): void {
        this.vars.set(name, value);
    }

    get(name: string): any {
        if (this.vars.has(name)) {
            return this.vars.get(name);
        }
        if (this.parent) {
            return this.parent.get(name);
        }
        throw new Error(`Undefined variable: ${name}`);
    }

    set(name: string, value: any): void {
        if (this.vars.has(name)) {
            this.vars.set(name, value);
            return;
        }
        if (this.parent) {
            this.parent.set(name, value);
            return;
        }
        throw new Error(`Undefined variable: ${name}`);
    }
}

class BreakException {}
class ContinueException {}
class ReturnException {
    constructor(public value: any) {}
}

export class Interpreter {
    private global: Environment;
    private loopIterations: number = 0;
    private maxLoopIterations: number = 100000;

    constructor(private graphAPI: GraphAPI) {
        this.global = new Environment();
        this.setupBuiltins();
    }

    private setupBuiltins(): void {
        // Data structure constructors
        this.global.define('queue', (): NetLangQueue => ({ type: 'queue', items: [] }));
        this.global.define('set', (): NetLangSet => ({ type: 'set', items: new Set() }));
        this.global.define('map', (): NetLangMap => ({ type: 'map', items: new Map() }));
        this.global.define('array', (): any[] => []);
        this.global.define('priority_queue', (): NetLangPriorityQueue => ({ type: 'pq', heap: [] }));

        // Queue operations
        this.global.define('enqueue', (q: NetLangQueue, item: any): null => {
            q.items.push(item);
            return null;
        });
        this.global.define('dequeue', (q: NetLangQueue): any => {
            if (q.items.length === 0) throw new Error('Queue is empty');
            return q.items.shift();
        });

        // Set operations
        this.global.define('add', (s: NetLangSet, item: any): null => {
            s.items.add(item);
            return null;
        });
        this.global.define('has', (s: NetLangSet, item: any): boolean => {
            return s.items.has(item);
        });

        // Map operations
        this.global.define('get', (m: NetLangMap, key: any): any => {
            return m.items.get(key);
        });
        this.global.define('put', (m: NetLangMap, key: any, value: any): null => {
            m.items.set(key, value);
            return null;
        });

        // Array operations
        this.global.define('push', (arr: any[], item: any): null => {
            arr.push(item);
            return null;
        });
        this.global.define('pop', (arr: any[]): any => {
            return arr.pop();
        });

        // Collection operations
        this.global.define('is_empty', (coll: NetLangCollection | any[]): boolean => {
            if (Array.isArray(coll)) return coll.length === 0;
            if (coll.type === 'queue') return coll.items.length === 0;
            if (coll.type === 'set') return coll.items.size === 0;
            if (coll.type === 'map') return coll.items.size === 0;
            return true;
        });

        this.global.define('size', (coll: NetLangCollection | any[]): number => {
            if (Array.isArray(coll)) return coll.length;
            if (coll.type === 'queue') return coll.items.length;
            if (coll.type === 'set') return coll.items.size;
            if (coll.type === 'map') return coll.items.size;
            return 0;
        });

        // Utility functions
        this.global.define('min', (a: number, b: number): number => Math.min(a, b));
        this.global.define('max', (a: number, b: number): number => Math.max(a, b));
        this.global.define('abs', (x: number): number => Math.abs(x));
        this.global.define('range', (start: number, end: number): number[] => {
            const arr: number[] = [];
            for (let i = start; i < end; i++) arr.push(i);
            return arr;
        });
        this.global.define('len', (coll: NetLangCollection | any[]): number => {
            if (Array.isArray(coll)) return coll.length;
            return this.global.get('size')(coll);
        });

        // Graph operations (delegated to API)
        this.global.define('nodes', (): number[] => this.graphAPI.nodes());
        this.global.define('neighbors', (id: number): number[] => this.graphAPI.neighbors(id));
        this.global.define('edges', () => this.graphAPI.edges());
        this.global.define('weight', (from: number, to: number) => this.graphAPI.weight(from, to));
        this.global.define('node_count', (): number => this.graphAPI.nodeCount());

        // Visualization operations
        this.global.define('highlight_node', (id: number, color: string): void => this.graphAPI.highlightNode(id, color));
        this.global.define('highlight_edge', (from: number, to: number, color: string): void => this.graphAPI.highlightEdge(from, to, color));
        this.global.define('set_node_label', (id: number, text: string): void => this.graphAPI.setNodeLabel(id, text));
        this.global.define('set_edge_label', (from: number, to: number, text: string): void => this.graphAPI.setEdgeLabel(from, to, text));
        this.global.define('log', (msg: string): void => this.graphAPI.log(msg));
        this.global.define('sleep', async (ms: number): Promise<void> => await this.graphAPI.sleep(ms));
    }

    async execute(program: Program): Promise<any> {
        this.loopIterations = 0;
        try {
            await this.evalStatements(program.statements, this.global);
        } catch (e) {
            if (e instanceof ReturnException) {
                return e.value;
            }
            throw e;
        }
    }

    private async evalStatements(statements: Statement[], env: Environment): Promise<void> {
        for (const stmt of statements) {
            await this.evalStatement(stmt, env);
        }
    }

    private async evalStatement(stmt: Statement, env: Environment): Promise<void> {
        switch (stmt.type) {
            case 'LetStatement': {
                const value = await this.evalExpression(stmt.value, env);
                env.define(stmt.name, value);
                break;
            }

            case 'AssignStatement': {
                const newValue = await this.evalExpression(stmt.value, env);
                env.set(stmt.name, newValue);
                break;
            }

            case 'IfStatement': {
                const condition = await this.evalExpression(stmt.condition, env);
                if (this.isTruthy(condition)) {
                    await this.evalStatements(stmt.thenBlock, env);
                } else if (stmt.elseBlock) {
                    await this.evalStatements(stmt.elseBlock, env);
                }
                break;
            }

            case 'WhileStatement': {
                while (this.isTruthy(await this.evalExpression(stmt.condition, env))) {
                    this.loopIterations++;
                    if (this.loopIterations > this.maxLoopIterations) {
                        throw new Error(`Infinite loop detected: exceeded ${this.maxLoopIterations} iterations`);
                    }
                    try {
                        await this.evalStatements(stmt.body, env);
                    } catch (e) {
                        if (e instanceof BreakException) break;
                        if (e instanceof ContinueException) continue;
                        throw e;
                    }
                }
                break;
            }

            case 'ForStatement': {
                const iterable = await this.evalExpression(stmt.iterable, env);
                const loopEnv = new Environment(env);
                const items = this.makeIterable(iterable);
                for (const item of items) {
                    this.loopIterations++;
                    if (this.loopIterations > this.maxLoopIterations) {
                        throw new Error(`Infinite loop detected: exceeded ${this.maxLoopIterations} iterations`);
                    }
                    loopEnv.define(stmt.variable, item);
                    try {
                        await this.evalStatements(stmt.body, loopEnv);
                    } catch (e) {
                        if (e instanceof BreakException) break;
                        if (e instanceof ContinueException) continue;
                        throw e;
                    }
                }
                break;
            }

            case 'FunctionDecl': {
                const func = async (...args: any[]): Promise<any> => {
                    const funcEnv = new Environment(env);
                    for (let i = 0; i < stmt.params.length; i++) {
                        funcEnv.define(stmt.params[i], args[i]);
                    }
                    try {
                        await this.evalStatements(stmt.body, funcEnv);
                        return null;
                    } catch (e) {
                        if (e instanceof ReturnException) {
                            return e.value;
                        }
                        throw e;
                    }
                };
                env.define(stmt.name, func);
                break;
            }

            case 'ReturnStatement': {
                const retValue = stmt.value ? await this.evalExpression(stmt.value, env) : null;
                throw new ReturnException(retValue);
            }

            case 'BreakStatement':
                throw new BreakException();

            case 'ContinueStatement':
                throw new ContinueException();

            case 'ExpressionStatement':
                await this.evalExpression(stmt.expression, env);
                break;
        }
    }

    private async evalExpression(expr: Expression, env: Environment): Promise<any> {
        switch (expr.type) {
            case 'Literal':
                return expr.value;

            case 'Identifier':
                return env.get(expr.name);

            case 'ArrayLiteral': {
                const arr: any[] = [];
                for (const elem of expr.elements) {
                    arr.push(await this.evalExpression(elem, env));
                }
                return arr;
            }

            case 'SetLiteral': {
                const s: NetLangSet = { type: 'set', items: new Set() };
                for (const elem of expr.elements) {
                    s.items.add(await this.evalExpression(elem, env));
                }
                return s;
            }

            case 'MapLiteral': {
                const m: NetLangMap = { type: 'map', items: new Map() };
                for (const pair of expr.pairs) {
                    const val = await this.evalExpression(pair.value, env);
                    m.items.set(pair.key, val);
                }
                return m;
            }

            case 'BinaryOp': {
                const left = await this.evalExpression(expr.left, env);
                const right = await this.evalExpression(expr.right, env);
                return this.evalBinaryOp(expr.operator, left, right);
            }

            case 'UnaryOp': {
                const operand = await this.evalExpression(expr.operand, env);
                if (expr.operator === 'not') return !this.isTruthy(operand);
                if (expr.operator === '-') return -operand;
                throw new Error(`Unknown unary operator: ${expr.operator}`);
            }

            case 'CallExpression': {
                const func = env.get(expr.name);
                const args: any[] = [];
                for (const arg of expr.args) {
                    args.push(await this.evalExpression(arg, env));
                }
                return await func(...args);
            }

            case 'MemberExpression': {
                const obj = await this.evalExpression(expr.object, env);
                return obj[expr.property];
            }

            case 'IndexExpression': {
                const array = await this.evalExpression(expr.object, env);
                const index = await this.evalExpression(expr.index, env);
                return array[index];
            }

            default:
                throw new Error(`Unknown expression type: ${(expr as any).type}`);
        }
    }

    private evalBinaryOp(op: string, left: any, right: any): any {
        switch (op) {
            case '+': return left + right;
            case '-': return left - right;
            case '*': return left * right;
            case '/': return left / right;
            case '%': return left % right;
            case '==': return left === right;
            case '!=': return left !== right;
            case '<': return left < right;
            case '>': return left > right;
            case '<=': return left <= right;
            case '>=': return left >= right;
            case 'and': return this.isTruthy(left) && this.isTruthy(right);
            case 'or': return this.isTruthy(left) || this.isTruthy(right);
            default: throw new Error(`Unknown operator: ${op}`);
        }
    }

    private isTruthy(value: any): boolean {
        if (value === null || value === false) return false;
        if (value === 0 || value === '') return false;
        return true;
    }

    private makeIterable(value: any): any[] {
        if (Array.isArray(value)) return value;
        if (value.type === 'set') return Array.from(value.items);
        if (value.type === 'map') return Array.from(value.items.keys());
        throw new Error('Value is not iterable');
    }
}

// Make classes available globally for browser use
if (typeof window !== 'undefined') {
    (window as any).Lexer = Lexer;
    (window as any).Parser = Parser;
    (window as any).Interpreter = Interpreter;
    (window as any).TokenType = TokenType;
}
