import { useRef, useState } from "react";
import { decodeExportString, ExportDecodeError } from "../lib/decodeExport";
import { parseSightingsJson } from "../lib/parseFromJson";
import type { Sighting } from "../lib/types";

interface Props {
  onImport: (sightings: Sighting[], label: string) => void;
}

export function ImportPanel({ onImport }: Props) {
  const [pasteValue, setPasteValue] = useState("");
  const [message, setMessage] = useState<{ kind: "ok" | "error"; text: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function handlePasteImport() {
    if (!pasteValue.trim()) return;
    try {
      const payload = decodeExportString(pasteValue);
      onImport(payload.sightings, `${payload.char}-${payload.realm}`);
      setMessage({
        kind: "ok",
        text: `Imported ${payload.sightings.length} sighting(s) from ${payload.char}-${payload.realm}.`,
      });
      setPasteValue("");
    } catch (err) {
      const text = err instanceof ExportDecodeError ? err.message : `Import failed: ${(err as Error).message}`;
      setMessage({ kind: "error", text });
    }
  }

  async function handleFileImport(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const text = await file.text();
      const json = JSON.parse(text);
      const sightings = parseSightingsJson(json);
      onImport(sightings, file.name);
      setMessage({ kind: "ok", text: `Imported ${sightings.length} sighting(s) from ${file.name}.` });
    } catch (err) {
      setMessage({ kind: "error", text: `Import failed: ${(err as Error).message}` });
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  return (
    <section className="panel import-panel">
      <h2>Import sightings</h2>
      <p className="muted">
        Paste a <code>/hw export</code> string from the addon, or upload a JSON file produced by{" "}
        <code>tools/parse-savedvariables</code>.
      </p>

      <div className="import-row">
        <textarea
          className="export-input"
          placeholder="Paste HordeWatch export string here..."
          value={pasteValue}
          onChange={(e) => setPasteValue(e.target.value)}
          rows={3}
        />
        <div className="import-actions">
          <button className="btn btn-primary" onClick={handlePasteImport} disabled={!pasteValue.trim()}>
            Import string
          </button>
          <label className="btn btn-secondary file-btn">
            Upload JSON
            <input ref={fileInputRef} type="file" accept="application/json,.json" onChange={handleFileImport} hidden />
          </label>
        </div>
      </div>

      {message && <div className={`import-message ${message.kind}`}>{message.text}</div>}
    </section>
  );
}
