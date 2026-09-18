import { useEffect, useState } from "react";
import ModulePageShell from "@/cfx-keydi-modules/ModulePageShell";
import { fetchNui } from "@/lib/nui";

export interface PatchNote {
  version: string;
  date: string;
  title: string;
  tag: string;
  notes: string[];
}

interface PatchNotesProps {
  onClose: () => void;
  initialUpdates?: PatchNote[];
}

export default function PatchNotes({ onClose, initialUpdates }: PatchNotesProps) {
  const [patchNotes, setPatchNotes] = useState<PatchNote[]>(initialUpdates || []);

  useEffect(() => {
    if (initialUpdates && initialUpdates.length > 0) {
      setPatchNotes(initialUpdates);
      return;
    }
    fetchNui<{ updates?: PatchNote[] }>("cfx-keydi-modules:getPatchNotes", {})
      .then((res) => {
        if (res?.updates) setPatchNotes(res.updates);
      })
      .catch(() => {});
  }, [initialUpdates]);

  return (
    <ModulePageShell
      title="Patch Notes"
      eyebrow="SERVER DEVELOPMENTS"
      subtitle="Read release notes and changelogs from the developers."
      sidebarHint="Latest server releases, bug fixes, and features."
      onClose={onClose}
    >
      <div className="flex flex-1 flex-col justify-between overflow-hidden">
        <div className="mb-2 max-h-[400px] flex-1 space-y-3.5 overflow-y-auto pr-2 custom-scrollbar">
          {patchNotes.length === 0 ? (
            <p className="rounded-xl border border-[#ff3a3a]/30 p-8 text-center text-xs text-[#a08890]">
              No patch notes available.
            </p>
          ) : (
            patchNotes.map((patch, idx) => (
              <div
                key={`${patch.version}-${idx}`}
                className="rounded-xl border border-[#ff3a3a]/30 bg-[#181216] p-4"
              >
                <div className="mb-2 flex items-center justify-between border-b border-[#ff3a3a]/20 pb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-bold tracking-wider text-[#ff4d4d]">
                      {patch.version}
                    </span>
                    <span className="text-[10px] text-[#a08890]">· {patch.date}</span>
                    {idx === 0 && (
                      <span className="text-[9px] font-black uppercase tracking-wider text-[#ff4d4d]">
                        Latest
                      </span>
                    )}
                  </div>
                  <span className="rounded border border-[#ff3a3a]/40 bg-[#ff3a3a]/20 px-2 py-0.5 text-[9px] font-black uppercase text-[#ff8080]">
                    {patch.tag}
                  </span>
                </div>
                <h4 className="text-xs font-bold text-white">{patch.title}</h4>
                <ul className="mt-2 space-y-1 pl-1">
                  {(patch.notes || []).map((note, nIdx) => (
                    <li
                      key={nIdx}
                      className="list-inside list-disc text-[10px] leading-relaxed text-[#a08890]"
                    >
                      {note}
                    </li>
                  ))}
                </ul>
              </div>
            ))
          )}
        </div>

        <div className="mt-2 flex justify-end border-t border-[#ff3a3a]/25 pt-3.5">
          <button
            type="button"
            onClick={onClose}
            className="cursor-pointer rounded-xl border border-[#ff3a3a] bg-[#ff3a3a] px-4 py-2 text-xs font-black uppercase tracking-wider text-white transition hover:brightness-110"
          >
            Return to Modules
          </button>
        </div>
      </div>
    </ModulePageShell>
  );
}
