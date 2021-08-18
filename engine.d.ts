declare module "engine" {
  export function System(...components:string[]): ISystem

  interface IEntity {
    [key:string]:any
  }

  interface ISystem {
    update: (callback:(entity:IEntity, dt:number)=>void) => ISystem
  }

  const engine: {
    load: () => void
  }

  export default engine
}