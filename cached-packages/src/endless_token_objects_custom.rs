// Copyright © Endless
// Copyright © Aptos Foundation

// SPDX-License-Identifier: Apache-2.0

#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(clippy::too_many_arguments)]
#![allow(clippy::arc_with_non_send_sync)]
#![allow(clippy::get_first)]
use endless_types::{
    account_address::AccountAddress,
    transaction::{EntryFunction, TransactionPayload},
};
use move_core_types::{
    ident_str,
    language_storage::{ModuleId, TypeTag},
};

type Bytes = Vec<u8>;

/// Structured representation of a call into a known Move entry function.
/// ```ignore
/// impl EntryFunctionCall {
///     pub fn encode(self) -> TransactionPayload { .. }
///     pub fn decode(&TransactionPayload) -> Option<EntryFunctionCall> { .. }
/// }
/// ```
#[derive(Clone, Debug, PartialEq, Eq)]
#[cfg_attr(feature = "fuzzing", derive(proptest_derive::Arbitrary))]
#[cfg_attr(feature = "fuzzing", proptest(no_params))]
pub enum EntryFunctionCall {
    /// Burn a token by its creator
    EndlessTokenBurn {
        token: AccountAddress,
    },
    EndlessTokenFreezeTransfer {
        token: AccountAddress,
    },
    EndlessTokenUnfreezeTransfer {
        token: AccountAddress,
    },
    EndlessTokenTransfer {
        token: AccountAddress,
        recipient: AccountAddress,
    },
    EndlessTokenSetDescription {
        token: AccountAddress,
        description: String,
    },
    EndlessTokenSetName {
        token: AccountAddress,
        name: String,
    },
    EndlessTokenSetUri {
        token: AccountAddress,
        uri: String,
    },
    EndlessTokenSetCollectionDescription {
        collection: AccountAddress,
        description: String,
    },
    EndlessTokenSetCollectionUri {
        collection: AccountAddress,
        uri: String,
    },
}

impl EntryFunctionCall {
    /// Build an Endless `TransactionPayload` from a structured object `EntryFunctionCall`.
    pub fn encode(self) -> TransactionPayload {
        use EntryFunctionCall::*;
        match self {
            EndlessTokenBurn { token } => endless_token_burn(token),
            EndlessTokenFreezeTransfer { token } => endless_token_freeze_transfer(token),
            EndlessTokenUnfreezeTransfer { token } => endless_token_unfreeze_transfer(token),
            EndlessTokenTransfer { token, recipient } => endless_token_transfer(token, recipient),
            EndlessTokenSetDescription { token, description } => {
                endless_token_set_description(token, description)
            },
            EndlessTokenSetName { token, name } => endless_token_set_name(token, name),
            EndlessTokenSetUri { token, uri } => endless_token_set_uri(token, uri),
            EndlessTokenSetCollectionDescription {
                collection,
                description,
            } => endless_token_set_collection_description(collection, description),
            EndlessTokenSetCollectionUri { collection, uri } => {
                endless_token_set_collection_uri(collection, uri)
            },
        }
    }

    /// Try to recognize an Endless `TransactionPayload` and convert it into a structured object `EntryFunctionCall`.
    pub fn decode(payload: &TransactionPayload) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            match SCRIPT_FUNCTION_DECODER_MAP.get(&format!(
                "{}_{}",
                script.module().name(),
                script.function()
            )) {
                Some(decoder) => decoder(payload),
                None => None,
            }
        } else {
            None
        }
    }
}

/// Burn a token by its creator.
pub fn endless_token_burn(token: AccountAddress) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("burn").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![bcs::to_bytes(&token).unwrap()],
    ))
}

/// Freeze a token transfer.
pub fn endless_token_freeze_transfer(token: AccountAddress) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("freeze_transfer").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![bcs::to_bytes(&token).unwrap()],
    ))
}

/// Unfreeze a token transfer.
pub fn endless_token_unfreeze_transfer(token: AccountAddress) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("unfreeze_transfer").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![bcs::to_bytes(&token).unwrap()],
    ))
}

/// Transfer a token to a recipient.
pub fn endless_token_transfer(
    token: AccountAddress,
    recipient: AccountAddress,
) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 1,
            ]),
            ident_str!("object").to_owned(),
        ),
        ident_str!("transfer").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![
            bcs::to_bytes(&token).unwrap(),
            bcs::to_bytes(&recipient).unwrap(),
        ],
    ))
}

pub fn endless_token_set_description(
    token: AccountAddress,
    description: String,
) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("set_description").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![
            bcs::to_bytes(&token).unwrap(),
            bcs::to_bytes(&description).unwrap(),
        ],
    ))
}

pub fn endless_token_set_name(token: AccountAddress, name: String) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("set_name").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![
            bcs::to_bytes(&token).unwrap(),
            bcs::to_bytes(&name).unwrap(),
        ],
    ))
}

pub fn endless_token_set_uri(token: AccountAddress, uri: String) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("set_uri").to_owned(),
        vec!["0x4::token::Token".parse().unwrap()],
        vec![bcs::to_bytes(&token).unwrap(), bcs::to_bytes(&uri).unwrap()],
    ))
}

pub fn endless_token_set_collection_description(
    collection: AccountAddress,
    description: String,
) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("set_collection_description").to_owned(),
        vec!["0x4::collection::Collection".parse().unwrap()],
        vec![
            bcs::to_bytes(&collection).unwrap(),
            bcs::to_bytes(&description).unwrap(),
        ],
    ))
}

pub fn endless_token_set_collection_uri(
    collection: AccountAddress,
    uri: String,
) -> TransactionPayload {
    TransactionPayload::EntryFunction(EntryFunction::new(
        ModuleId::new(
            AccountAddress::new([
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 4,
            ]),
            ident_str!("endless_token").to_owned(),
        ),
        ident_str!("set_collection_uri").to_owned(),
        vec!["0x4::collection::Collection".parse().unwrap()],
        vec![
            bcs::to_bytes(&collection).unwrap(),
            bcs::to_bytes(&uri).unwrap(),
        ],
    ))
}

mod decoder {
    use super::*;
    pub fn endless_token_burn(payload: &TransactionPayload) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenBurn {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_freeze_transfer(
        payload: &TransactionPayload,
    ) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenFreezeTransfer {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_unfreeze_transfer(
        payload: &TransactionPayload,
    ) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenUnfreezeTransfer {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_transfer(payload: &TransactionPayload) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenTransfer {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
                recipient: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_set_description(
        payload: &TransactionPayload,
    ) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenSetDescription {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
                description: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_set_name(payload: &TransactionPayload) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenSetName {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
                name: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_set_uri(payload: &TransactionPayload) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenSetUri {
                token: bcs::from_bytes(script.args().get(0)?).ok()?,
                uri: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_set_collection_description(
        payload: &TransactionPayload,
    ) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenSetCollectionDescription {
                collection: bcs::from_bytes(script.args().get(0)?).ok()?,
                description: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }

    pub fn endless_token_set_collection_uri(
        payload: &TransactionPayload,
    ) -> Option<EntryFunctionCall> {
        if let TransactionPayload::EntryFunction(script) = payload {
            Some(EntryFunctionCall::EndlessTokenSetCollectionUri {
                collection: bcs::from_bytes(script.args().get(0)?).ok()?,
                uri: bcs::from_bytes(script.args().get(1)?).ok()?,
            })
        } else {
            None
        }
    }
}

type EntryFunctionDecoderMap = std::collections::HashMap<
    String,
    Box<
        dyn Fn(&TransactionPayload) -> Option<EntryFunctionCall>
            + std::marker::Sync
            + std::marker::Send,
    >,
>;

static SCRIPT_FUNCTION_DECODER_MAP: once_cell::sync::Lazy<EntryFunctionDecoderMap> =
    once_cell::sync::Lazy::new(|| {
        let mut map: EntryFunctionDecoderMap = std::collections::HashMap::new();
        map.insert(
            "endless_token_burn".to_string(),
            Box::new(decoder::endless_token_burn),
        );
        map.insert(
            "endless_token_freeze_transfer".to_string(),
            Box::new(decoder::endless_token_freeze_transfer),
        );
        map.insert(
            "endless_token_unfreeze_transfer".to_string(),
            Box::new(decoder::endless_token_unfreeze_transfer),
        );
        map.insert(
            "endless_token_transfer".to_string(),
            Box::new(decoder::endless_token_transfer),
        );
        map.insert(
            "endless_token_set_description".to_string(),
            Box::new(decoder::endless_token_set_description),
        );
        map.insert(
            "endless_token_set_name".to_string(),
            Box::new(decoder::endless_token_set_name),
        );
        map.insert(
            "endless_token_set_uri".to_string(),
            Box::new(decoder::endless_token_set_uri),
        );
        map.insert(
            "endless_token_set_collection_description".to_string(),
            Box::new(decoder::endless_token_set_collection_description),
        );
        map.insert(
            "endless_token_set_collection_uri".to_string(),
            Box::new(decoder::endless_token_set_collection_uri),
        );
        map
    });
