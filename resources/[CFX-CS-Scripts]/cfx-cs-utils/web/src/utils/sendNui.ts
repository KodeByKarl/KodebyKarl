export async function sendNuiEvent(eventName: string, data: any = {}) {
  if (typeof GetParentResourceName === 'undefined') {
    throw new Error('sendNuiEvent called outside of NUI context');
  }
  const response = await fetch(`https://${GetParentResourceName()}/${eventName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    throw new Error(`NUI fetch failed`);
  }
  try {
    return await response.json();
  } catch {
    return await response.text();
  }
}

declare function GetParentResourceName(): string;
