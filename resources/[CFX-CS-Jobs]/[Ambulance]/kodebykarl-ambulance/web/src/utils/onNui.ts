interface NuiMessageData {
  type: string;
  [key: string]: any;
}

export const onNuiEvent = <T = any>(
  action: string, 
  callback: (data: T) => void
): (() => void) => {
    const listener = (event: MessageEvent<NuiMessageData>) => {
        const { type, ...data } = event.data;
        
        if (type === action) {
            callback(data as unknown as T);
        }
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
};