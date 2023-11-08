import * as ads from './ads';
import { AdMobConfig, Events, execAsync } from './common';

export * from './ads';
export * from './common';

export class AdMob {
  public readonly BannerAd = ads.BannerAd;

  public readonly Events = Events;

  private _startPromise: ReturnType<typeof this._start> | undefined;

  configure(config: AdMobConfig) {
    return execAsync('configure', [config]);
  }

  public start() {
    return (this._startPromise ??= this._start());
  }

  private _start() {
    return execAsync<{ version: string }>('start');
  }
}

declare global {
  const admob: AdMob;
}

export default AdMob;
