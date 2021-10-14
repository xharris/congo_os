declare module "map" {
  const map: {
    Tiled: {
      load: (luafile_path: string) => TiledMap;
    };
  };

  interface Map {
    addTile(
      image: string,
      x: number,
      y: number,
      tx: number,
      ty: number,
      tw: number,
      th: number,
      layer?: string
    );
    removeTile(
      x: number,
      y: number,
      w: number,
      h: number,
      layer?: string,
      image?: string
    );
    addEntity(entity: Entity);
  }

  type TiledMap = {
    // straight from Tiled file
    tilesets: any[];
    layers:
      | {
          type: "tilelayer";
          name: string;
          tiles: [
            image: string,
            x: number,
            y: number,
            tx: number,
            ty: number,
            tw: number,
            th: number,
            layer: string
          ][];
        }
      | {
          type: "objectgroup";
          // ...Tiled objectgroup
        }[];
  };
}
