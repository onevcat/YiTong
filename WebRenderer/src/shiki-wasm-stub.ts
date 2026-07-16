export async function getWasmInstance(): Promise<never> {
  throw new Error("YiTong embeds the JavaScript Shiki engine, not the WASM engine");
}

export default getWasmInstance;
