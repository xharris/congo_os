export declare function System(...components:string[]): ISystem

interface IEntity {
  [key:string]:any
}

interface ISystem {
  update: (callback:(entity:IEntity, ...args:any[])=>void) => ISystem
}

declare const engine: {
  load: () => void
}

export default engine