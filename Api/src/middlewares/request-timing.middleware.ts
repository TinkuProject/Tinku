import { NextFunction, Request, Response } from "express";

export function requestTiming(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime.bigint();

  res.on("finish", () => {
    const elapsedNs = process.hrtime.bigint() - start;
    const elapsedMs = Number(elapsedNs) / 1_000_000;
    const slowThreshold = Number(process.env.API_SLOW_REQUEST_MS ?? 500);
    const logAll = process.env.API_LOG_REQUESTS === "true";

    if (!logAll && elapsedMs < slowThreshold) return;

    console.log(
      `[api] ${req.method} ${req.originalUrl} ${res.statusCode} ${elapsedMs.toFixed(1)}ms`
    );
  });

  next();
}

