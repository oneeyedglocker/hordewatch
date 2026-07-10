import luaparse from "luaparse";

// WoW's SavedVariables serializer only ever emits plain table literals -
// strings, numbers, booleans, nil, and nested tables, never metatables,
// functions, or cycles (see DATA_MODEL.md) - so this evaluator only needs
// to handle that subset of the Lua grammar.

function evalExpr(node) {
  switch (node.type) {
    case "StringLiteral":
      return node.value;
    case "NumericLiteral":
      return node.value;
    case "BooleanLiteral":
      return node.value;
    case "NilLiteral":
      return undefined;
    case "UnaryExpression":
      if (node.operator === "-") return -evalExpr(node.argument);
      if (node.operator === "not") return !evalExpr(node.argument);
      throw new Error(`Unsupported unary operator in SavedVariables: ${node.operator}`);
    case "TableConstructorExpression":
      return evalTable(node);
    default:
      throw new Error(`Unsupported Lua expression in SavedVariables: ${node.type}`);
  }
}

function evalTable(node) {
  const entries = [];
  let nextArrayIndex = 1;
  for (const field of node.fields) {
    if (field.type === "TableKey") {
      const key = evalExpr(field.key);
      const value = evalExpr(field.value);
      entries.push([key, value]);
    } else if (field.type === "TableKeyString") {
      entries.push([field.key.name, evalExpr(field.value)]);
    } else if (field.type === "TableValue") {
      entries.push([nextArrayIndex++, evalExpr(field.value)]);
    } else {
      throw new Error(`Unsupported table field type in SavedVariables: ${field.type}`);
    }
  }

  const numericKeys = entries.map(([k]) => k).filter((k) => typeof k === "number");
  if (numericKeys.length === entries.length && entries.length > 0) {
    const sorted = [...numericKeys].sort((a, b) => a - b);
    if (sorted.every((k, idx) => k === idx + 1)) {
      const byKey = new Map(entries);
      return sorted.map((k) => byKey.get(k));
    }
  }

  const obj = {};
  for (const [k, v] of entries) obj[String(k)] = v;
  return obj;
}

/** Parses a WoW SavedVariables .lua file's source and returns the value
 * assigned to `globalName` (e.g. "HordeWatchCharDB"), or undefined if that
 * global isn't assigned in the file. */
export function extractGlobalTable(luaSource, globalName) {
  const ast = luaparse.parse(luaSource, {
    encodingMode: "pseudo-latin1", // treat the file as a raw byte string, same as the web app's decoder
    comments: false,
  });

  for (const stmt of ast.body) {
    if (stmt.type !== "AssignmentStatement") continue;
    const idx = stmt.variables.findIndex((v) => v.type === "Identifier" && v.name === globalName);
    if (idx === -1) continue;
    return evalExpr(stmt.init[idx]);
  }
  return undefined;
}
