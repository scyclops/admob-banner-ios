import { execAsync, MobileAd, NativeActions, MobileAdOptions } from './shared'

export class GenericAd<S = Record<string, any>> extends MobileAd {
  private _init: Promise<void> | null

  constructor(opts: MobileAdOptions & { type: string; _noinit?: boolean }) {
    super(opts)

    if (opts._noinit) {
      this._init = null
    } else {
      // TODO utilize `createAd`
      this._init = execAsync(NativeActions.adCreate, [
        { ...opts, id: this.id, type: opts.type },
      ]).then(() => {
        this._init = null
      })
    }
  }

  async isLoaded() {
    await this.init()
    return execAsync(NativeActions.adIsLoaded, [
      { id: this.id },
    ]) as Promise<boolean>
  }

  async load() {
    await this.init()
    await execAsync(NativeActions.adLoad, [{ id: this.id }])
  }

  async show(opts?: S) {
    await this.init()
    return execAsync(NativeActions.adShow, [
      { ...opts, id: this.id },
    ]) as Promise<boolean>
  }

  protected async init() {
    if (this._init !== null) await this._init
  }
}

export default class AppOpenAd extends GenericAd {
  public static readonly type = 'app-open'

  constructor(opts: MobileAdOptions) {
    super({ ...opts, type: AppOpenAd.type })
  }
}