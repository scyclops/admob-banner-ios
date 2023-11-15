export const CordovaService = 'AdMob';

export type CordovaAction =
  | 'adCreate'
  | 'adHide'
  | 'adIsLoaded'
  | 'adLoad'
  | 'adShow'
  | 'bannerConfig'
  | 'configure'
  | 'ready'
  | 'start';

export enum Events {
  adClick = 'admob.ad.click',
  adDismiss = 'admob.ad.dismiss',
  adImpression = 'admob.ad.impression',
  adLoad = 'admob.ad.load',
  adLoadFail = 'admob.ad.loadfail',
  adShow = 'admob.ad.show',
  adShowFail = 'admob.ad.showfail',
  bannerSize = 'admob.banner.size',
  ready = 'admob.ready',
}

export const enum Platform {
  ios = 'ios',
}

/**
 * An enum that represents the maximum ad content rating for an app or ad request.
 * @enum {string}
 */
type MaxAdContentRating =
  | /** Content suitable for general audiences, including families. */ 'G'
  | /** Content suitable only for mature audiences. */ 'MA'
  | /** Content suitable for most audiences with parental guidance. */ 'PG'
  | /** Content suitable for teen and older audiences. */ 'T'
  | /** Content suitability is unspecified. */ '';

export interface RequestConfig {
  maxAdContentRating?: MaxAdContentRating;
  tagForChildDirectedTreatment?: boolean | null;
  tagForUnderAgeOfConsent?: boolean | null;
  testDeviceIds?: string[];
}

export interface AdMobConfig extends RequestConfig {
  appMuted?: boolean;
  appVolume?: number;
  sameAppKey?: boolean;
}

/** @internal */
export function execAsync<T>(action: CordovaAction, args?: unknown[]) {
  return new Promise<T>((resolve, reject) => {
    cordova.exec(resolve, reject, CordovaService, action, args);
  });
}