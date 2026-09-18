import { useCallback, useEffect, useState } from "react";
import { Briefcase, CheckCircle2, Power, ShieldAlert } from "lucide-react";
import { cn } from "@/lib/utils";
import ModulePageShell from "@/cfx-keydi-modules/ModulePageShell";
import { fetchNui, isBrowserEnv } from "@/lib/nui";

interface JobItem {
  job: string;
  grade: number;
  label: string;
  grade_label: string;
  is_active: number;
}

interface MultiJobProps {
  onClose: () => void;
}

export default function MultiJob({ onClose }: MultiJobProps) {
  const [jobsList, setJobsList] = useState<JobItem[]>([]);
  const [activeJob, setActiveJob] = useState<string | null>(null);
  const [loadingJobs, setLoadingJobs] = useState(false);

  const loadMultiJobs = useCallback(() => {
    setLoadingJobs(true);
    fetchNui<{ jobs: JobItem[]; activeJob: string | null; isOnDuty: boolean }>(
      "cfx-keydi-modules:getJobs",
      {}
    )
      .then((res) => {
        if (res) {
          setJobsList(res.jobs || []);
          setActiveJob(res.activeJob || null);
        }
      })
      .catch(() => {})
      .finally(() => setLoadingJobs(false));
  }, []);

  useEffect(() => {
    loadMultiJobs();
  }, [loadMultiJobs]);

  const handleToggleJobDuty = (jobName: string) => {
    if (isBrowserEnv()) {
      setActiveJob(jobName);
      setJobsList((prev) =>
        prev.map((j) => ({ ...j, is_active: j.job === jobName ? 1 : 0 }))
      );
      return;
    }
    fetchNui("cfx-keydi-modules:toggleJobDuty", { job: jobName })
      .then(() => {
        setTimeout(() => loadMultiJobs(), 300);
      })
      .catch(() => {});
  };

  return (
    <ModulePageShell
      title="Multi-Job Roster"
      eyebrow="MULTI-JOB ROSTER"
      subtitle="Switch active job duty position on demand."
      sidebarHint="Max 3 held jobs. Clock on one duty at a time."
      onClose={onClose}
    >
      <div className="flex flex-1 flex-col justify-between overflow-hidden">
        <div className="mb-2 flex-1 space-y-3 overflow-y-auto pr-2 custom-scrollbar">
          <div className="flex items-center justify-between rounded-xl border border-[#ff3a3a]/40 bg-[#ff3a3a]/10 p-3.5">
            <div className="flex items-center gap-3">
              <ShieldAlert className="h-4.5 w-4.5 shrink-0 text-[#ff4d4d]" />
              <div className="flex flex-col text-left">
                <span className="text-[11px] font-bold text-white">Multi-Job Duty Protocol</span>
                <span className="mt-0.5 text-[9.5px] text-[#a08890]">
                  Maximum 3 held jobs allowed. You can only be ON DUTY at 1 job at a time.
                </span>
              </div>
            </div>
            <span className="shrink-0 rounded-lg border border-[#ff3a3a] bg-[#ff3a3a] px-2.5 py-1 text-[10px] font-black uppercase tracking-wider text-white">
              {jobsList.length} / 3 HELD
            </span>
          </div>

          {loadingJobs ? (
            <div className="py-8 text-center text-xs text-[#a08890]">Loading Multi-Job Roster...</div>
          ) : jobsList.length === 0 ? (
            <div className="py-8 text-center text-xs text-[#a08890]">
              No employment positions found. Get hired by a business or gang!
            </div>
          ) : (
            jobsList.map((jobItem) => {
              const isJobActive = activeJob === jobItem.job;
              return (
                <div
                  key={jobItem.job}
                  className={cn(
                    "flex items-center justify-between rounded-xl border p-3.5 transition bg-[#181216]",
                    isJobActive ? "border-[#ff3a3a] bg-[#ff3a3a]/15" : "border-white/10"
                  )}
                >
                  <div className="flex items-center gap-3">
                    <div
                      className={cn(
                        "flex h-9 w-9 items-center justify-center rounded-lg border",
                        isJobActive
                          ? "border-[#ff3a3a] bg-[#ff3a3a] text-white"
                          : "border-white/10 bg-[#0d0d12] text-[#a08890]"
                      )}
                    >
                      <Briefcase className="h-4.5 w-4.5" />
                    </div>
                    <div className="flex flex-col text-left">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-white">{jobItem.label}</span>
                        {isJobActive && (
                          <span className="flex items-center gap-1 rounded-md border border-emerald-500/30 bg-emerald-500/15 px-2 py-0.5 text-[8.5px] font-black uppercase text-emerald-400">
                            <CheckCircle2 className="h-3 w-3" /> ACTIVE ON DUTY
                          </span>
                        )}
                      </div>
                      <span className="mt-0.5 text-[9.5px] text-[#a08890]">
                        Rank Grade: {jobItem.grade_label} (Grade {jobItem.grade})
                      </span>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() => handleToggleJobDuty(jobItem.job)}
                    className={cn(
                      "flex shrink-0 cursor-pointer items-center gap-1.5 rounded-lg border px-3.5 py-1.5 text-xs font-black uppercase tracking-wider transition",
                      isJobActive
                        ? "border-red-500/40 bg-red-500/20 text-red-400 hover:bg-red-500/30"
                        : "border-[#ff3a3a] bg-[#ff3a3a] text-white hover:brightness-110"
                    )}
                  >
                    <Power className="h-3.5 w-3.5" />
                    {isJobActive ? "Clock Off" : "Clock On"}
                  </button>
                </div>
              );
            })
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
